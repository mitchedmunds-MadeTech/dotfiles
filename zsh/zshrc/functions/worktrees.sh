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

gwt-add() {
    [ -z "$1" ] && { echo "Usage: gwt-add <worktree-name> [branch-name]" >&2; return 1; }
    local dir worktree_path branch
    dir=$(_gwt_dir) || { echo "Not inside a git repository" >&2; return 1; }
    worktree_path="${dir}/$1"
    branch="${2:-$1}"
    mkdir -p "$dir"
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
        git worktree add "$worktree_path" "$branch"
    else
        git worktree add -b "$branch" "$worktree_path"
    fi
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

# Remove worktrees and local branches whose upstream has been deleted on the
# remote (typical after a rebase-merge + branch delete on GitHub). Dry-run by
# default — pass --force (or -f) to actually remove. --no-fetch skips the
# initial `git fetch --prune`.
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

    local branches
    branches=$(_gwt_gone)
    if [ -z "$branches" ]; then
        echo "No gone branches. Nothing to prune."
        return 0
    fi

    local current_wt branch wt_path
    current_wt=$(git rev-parse --show-toplevel 2>/dev/null || true)

    printf '%s\n' "$branches" | while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        wt_path=$(_gwt_path_of "$branch")
        if [ -n "$wt_path" ] && [ "$wt_path" = "$current_wt" ]; then
            echo "  [skip] $branch — checked out in the current worktree"
            continue
        fi
        if [ "$force" -eq 0 ]; then
            [ -n "$wt_path" ] && echo "  would remove worktree: $wt_path"
            echo "  would delete branch:   $branch"
        else
            if [ -n "$wt_path" ]; then
                if git worktree remove "$wt_path"; then
                    echo "  removed worktree: $wt_path"
                else
                    echo "  failed to remove worktree $wt_path (uncommitted changes? re-run 'git worktree remove --force $wt_path' manually)" >&2
                    continue
                fi
            fi
            if git branch -D "$branch" >/dev/null; then
                echo "  deleted branch:   $branch"
            else
                echo "  failed to delete branch: $branch" >&2
            fi
        fi
    done

    [ "$force" -eq 0 ] && { echo ""; echo "(dry run — re-run with --force to actually delete)"; }
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
