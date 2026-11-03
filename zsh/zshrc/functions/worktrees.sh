# Internal helper: prints the absolute path to the worktrees dir for this repo
_gwt_dir() {
    local git_common_dir main_repo project_name
    git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
    main_repo=$(dirname "$git_common_dir")
    project_name=$(basename "$main_repo")
    printf '%s\n' "$(dirname "$main_repo")/${project_name}_worktrees"
}

# Internal helper: lists names of existing worktrees under the worktrees dir
gwt-ls() {
    local dir
    dir=$(_gwt_dir) || return 1
    git worktree list --porcelain 2>/dev/null | awk -v d="${dir}/" '
        /^worktree / {
            path = substr($0, 10)
            if (substr(path, 1, length(d)) == d) print substr(path, length(d) + 1)
        }
    '
}

# Internal helper: seeds a new worktree's pytest-testmon database from the
# most recently run one among the other worktrees, so its first push does not
# run the whole suite (long enough for GitHub to drop the idle push connection).
# A stale copy only makes testmon rerun more tests, since it compares each
# test's code fingerprints. SQLite's backup API rather than cp: testmon keeps
# recent writes in a -wal file beside the database, and a run may be writing to
# it. Python's stdlib sqlite3 through uv, since the sqlite3 CLI is not on every
# machine (the Dev Container has none) and uv is already required.
_gwt_seed_testmon() {
    local dest="$1" newest="" wt_path line
    [ -e "$dest/.testmondata" ] && return 0
    command -v uv >/dev/null 2>&1 || return 0
    while IFS= read -r line; do
        case "$line" in "worktree "*) ;; *) continue ;; esac
        wt_path="${line#worktree }"
        [ "$wt_path" = "$dest" ] && continue
        [ -f "$wt_path/.testmondata" ] || continue
        if [ -z "$newest" ] || [ "$wt_path/.testmondata" -nt "$newest" ]; then
            newest="$wt_path/.testmondata"
        fi
    done < <(git worktree list --porcelain 2>/dev/null)
    [ -n "$newest" ] || return 0
    echo "→ testmon database from ${newest%/.testmondata}"
    uv run --no-project python -c '
import sqlite3, sys
src, dst = sqlite3.connect(sys.argv[1]), sqlite3.connect(sys.argv[2])
src.backup(dst)
dst.close()
src.close()
' "$newest" "$dest/.testmondata" \
        || echo "testmon seed failed — first push runs the whole suite" >&2
}

gwt-add() {
    [ -z "$1" ] && { echo "Usage: gwt-add <worktree-name> [branch-name] [--no-sync]" >&2; return 1; }
    local dir worktree_path branch sync=1 a
    local args=()
    for a in "$@"; do
        case "$a" in
            --no-sync) sync=0 ;;
            *) args+=("$a") ;;
        esac
    done
    set -- "${args[@]}"
    dir=$(_gwt_dir) || { echo "Not inside a git repository" >&2; return 1; }
    worktree_path="${dir}/$1"
    branch="${2:-$1}"
    mkdir -p "$dir"
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
        git worktree add "$worktree_path" "$branch" || return $?
    else
        git worktree add -b "$branch" "$worktree_path" || return $?
    fi
    if [ "$sync" -eq 0 ]; then
        _gwt_seed_testmon "$worktree_path"
        return 0
    fi
    # A repo that ships its own setup recipe knows its steps best.
    if command -v just >/dev/null 2>&1 \
        && just --justfile "$worktree_path/justfile" --show worktree-setup >/dev/null 2>&1; then
        echo "→ just worktree-setup ($1)"
        (cd "$worktree_path" && just worktree-setup) || echo "just worktree-setup failed" >&2
        return 0
    fi
    # uv-managed Python projects need a venv for ty / pytest / etc. hooks to
    # find packages. Sync it now so the first pre-commit or pre-push in the
    # new worktree doesn't fail with unresolved-import errors. Opt out with
    # --no-sync.
    if [ "$sync" -eq 1 ] \
        && [ -f "$worktree_path/pyproject.toml" ] \
        && [ -f "$worktree_path/uv.lock" ] \
        && command -v uv >/dev/null 2>&1; then
        echo "→ uv sync ($1)"
        (cd "$worktree_path" && uv sync) || echo "uv sync failed — venv not ready" >&2
    fi
    _gwt_seed_testmon "$worktree_path"
}

gwt-rm() {
    [ -z "$1" ] && { echo "Usage: gwt-rm <worktree-name> [--force]" >&2; return 1; }
    local dir
    dir=$(_gwt_dir) || { echo "Not inside a git repository" >&2; return 1; }
    git worktree remove "${dir}/$1" "${@:2}"
}

# Internal helper: lists local branches whose upstream is [gone], excluding
# protected names (main, master, develop) and the current branch.
_gwt_gone() {
    local current branch upstream
    current=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
    while IFS=' ' read -r branch upstream; do
        [ "$upstream" = "[gone]" ] || continue
        case "$branch" in main|master|develop) continue ;; esac
        [ "$branch" = "$current" ] && continue
        printf '%s\n' "$branch"
    done < <(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ 2>/dev/null)
}

# Internal helper: prints the worktree path for a branch (empty if none).
# Uses `wt_path` rather than `path`: in zsh, `path` is the array form of
# `$PATH`, and `local path` clobbers it for the function's scope.
_gwt_path_of() {
    local target="refs/heads/$1" wt_path="" line
    while IFS= read -r line; do
        case "$line" in
            "worktree "*) wt_path="${line#worktree }" ;;
            "branch $target") printf '%s\n' "$wt_path"; return 0 ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null)
}

# Internal helper: prints every PR of the current repo's GitHub remote as
# "<head branch>\t<state>\t<head sha>", or fails when gh is missing, not
# logged in, or cannot reach GitHub.
_gwt_prs() {
    command -v gh >/dev/null 2>&1 || return 1
    gh pr list --state all --limit 5000 --json headRefName,state,headRefOid \
        --jq '.[] | "\(.headRefName)\t\(.state)\t\(.headRefOid)"' 2>/dev/null
}

# Internal helper: lists local branches whose PR merged and whose tip is that
# PR's head commit or an ancestor of it, so nothing committed after the merge
# is lost. Matching on the head commit rather than on commits missing from
# main is the point: a rebase-merge re-hashes every commit, so a merged
# branch still looks unmerged to `git branch --merged` and `git cherry`. It
# also catches branches gwt-prune's [gone] check misses: never pushed with
# -u, remote branch not deleted, or tracking origin/main because the branch
# was created with `git branch <name> origin/main`.
_gwt_merged() {
    local prs="$1" current branch tip oid
    current=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
    while IFS= read -r branch; do
        case "$branch" in main|master|develop) continue ;; esac
        [ "$branch" = "$current" ] && continue
        tip=$(git rev-parse --verify --quiet "refs/heads/$branch") || continue
        while IFS= read -r oid; do
            [ -z "$oid" ] && continue
            if [ "$tip" = "$oid" ] \
                || { git cat-file -e "${oid}^{commit}" 2>/dev/null \
                     && git merge-base --is-ancestor "$tip" "$oid" 2>/dev/null; }; then
                printf '%s\n' "$branch"
                break
            fi
        done < <(awk -F'\t' -v b="$branch" '$1 == b && $2 == "MERGED" { print $3 }' <<<"$prs")
    done < <(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
}

# Internal helper: the state of a branch's PR, preferring an open one when a
# branch name has been reused, or "none".
_gwt_pr_state() {
    awk -F'\t' -v b="$2" '
        $1 == b { seen[$2] = 1 }
        END {
            if ("OPEN" in seen) print "OPEN"
            else if ("MERGED" in seen) print "MERGED"
            else if ("CLOSED" in seen) print "CLOSED"
            else print "none"
        }' <<<"$1"
}

# Remove worktrees and local branches that are finished with: those whose
# upstream has been deleted on the remote ([gone], typical after a
# rebase-merge and branch delete on GitHub), and, when gh is available, those
# whose PR merged with this exact tip. A worktree with uncommitted changes is
# never removed. Then lists the worktrees left alone that may need a look:
# uncommitted changes, a closed PR, no PR, or a detached HEAD.
#
# Dry-run by default — pass --force (or -f) to actually remove. --no-fetch
# skips the initial `git fetch --prune`.
gwt-prune() {
    local force=0 fetch=1 a
    for a in "$@"; do
        case "$a" in
            -f|--force) force=1 ;;
            --no-fetch) fetch=0 ;;
            -h|--help)
                echo "Usage: gwt-prune [--force|-f] [--no-fetch]" >&2
                return 0 ;;
            *) echo "gwt-prune: unknown arg '$a'" >&2; return 1 ;;
        esac
    done

    git rev-parse --git-dir >/dev/null 2>&1 || { echo "Not inside a git repository" >&2; return 1; }
    [ "$fetch" -eq 1 ] && git fetch --prune --quiet

    local prs="" have_prs=0
    if prs=$(_gwt_prs) && [ -n "$prs" ]; then
        have_prs=1
    else
        echo "(gh unavailable — checking [gone] upstreams only)"
    fi

    local branches
    branches=$( { _gwt_gone; [ "$have_prs" -eq 1 ] && _gwt_merged "$prs"; } | awk '!seen[$0]++')

    local current_wt main_wt branch wt_path dirty pruned=""
    current_wt=$(git rev-parse --show-toplevel 2>/dev/null || true)
    main_wt=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")

    if [ -z "$branches" ]; then
        echo "Nothing to prune."
    fi
    while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        wt_path=$(_gwt_path_of "$branch")
        if [ -n "$wt_path" ] && [ "$wt_path" = "$current_wt" ]; then
            echo "  [skip] $branch — checked out in the current worktree"
            continue
        fi
        if [ -n "$wt_path" ]; then
            dirty=$(git -C "$wt_path" status --porcelain 2>/dev/null)
            if [ -n "$dirty" ]; then
                echo "  [skip] $branch — finished, but its worktree has uncommitted changes (listed below)"
                continue
            fi
        fi
        pruned="${pruned}${branch}"$'\n'
        if [ "$force" -eq 0 ]; then
            [ -n "$wt_path" ] && echo "  would remove worktree: $wt_path"
            echo "  would delete branch:   $branch"
        else
            if [ -n "$wt_path" ]; then
                if git worktree remove "$wt_path"; then
                    echo "  removed worktree: $wt_path"
                else
                    echo "  failed to remove worktree $wt_path" >&2
                    continue
                fi
            fi
            if git branch -D "$branch" >/dev/null; then
                echo "  deleted branch:   $branch"
            else
                echo "  failed to delete branch: $branch" >&2
            fi
        fi
    done <<<"$branches"

    [ "$force" -eq 0 ] && { echo ""; echo "(dry run — re-run with --force to actually delete)"; }

    # Worktrees left alone. An open PR is active work and is not listed.
    local line state age label header=0
    wt_path="" branch=""
    while IFS= read -r line; do
        case "$line" in
            "worktree "*) wt_path="${line#worktree }"; branch="" ;;
            "branch refs/heads/"*) branch="${line#branch refs/heads/}" ;;
            "detached") branch="(detached)" ;;
            "")
                if [ -n "$wt_path" ] && [ "$wt_path" != "$main_wt" ] && [ -d "$wt_path" ] \
                    && ! printf '%s' "$pruned" | grep -qxF -- "$branch"; then
                    dirty=$(git -C "$wt_path" status --porcelain 2>/dev/null)
                    if [ "$branch" = "(detached)" ]; then
                        label="detached"
                    elif [ "$have_prs" -eq 1 ]; then
                        state=$(_gwt_pr_state "$prs" "$branch")
                        case "$state" in
                            OPEN) label="" ;;
                            MERGED) label="merged, tip differs" ;;
                            CLOSED) label="PR closed" ;;
                            *) label="no PR" ;;
                        esac
                    else
                        label=""
                    fi
                    [ -n "$dirty" ] && label="${label:+$label, }uncommitted changes"
                    if [ -n "$label" ]; then
                        if [ "$header" -eq 0 ]; then
                            echo ""
                            echo "Left alone — check these:"
                            header=1
                        fi
                        age=$(git -C "$wt_path" log -1 --format=%cr 2>/dev/null)
                        printf '  %-46s %-14s %s\n' "[$label]" "$age" "${wt_path##*/}"
                        [ -n "$dirty" ] && printf '%s\n' "$dirty" | head -3 | sed 's/^/      /'
                    fi
                fi
                wt_path="" branch="" ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null; echo)
}

# --- Completion ---

_gwt_rm_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$(gwt-ls)" -- "$cur") )
    fi
}

_gwt_add_complete() {
    if [ "$COMP_CWORD" -eq 2 ]; then
        local cur="${COMP_WORDS[COMP_CWORD]}" branches
        branches=$(git for-each-ref --format='%(refname:short)' refs/heads/ refs/remotes/ 2>/dev/null)
        COMPREPLY=( $(compgen -W "$branches" -- "$cur") )
    else
        COMPREPLY=()
    fi
}
_gwt_prune_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=( $(compgen -W "--force --no-fetch --help" -- "$cur") )
}
complete -F _gwt_add_complete gwt-add
complete -F _gwt_rm_complete gwt-rm
complete -F _gwt_prune_complete gwt-prune
