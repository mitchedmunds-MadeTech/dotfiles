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
complete -F _gwt_add_complete gwt-add
complete -F _gwt_rm_complete gwt-rm
