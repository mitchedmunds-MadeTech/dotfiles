# Reclaim disk from Colima's Docker VM: prune stopped containers, unused images
# and build cache, then fstrim so the freed blocks go back to macOS. Without the
# fstrim the VM's data disk (~/.colima/_lima/_disks/colima/datadisk) stays at its
# largest size however much Docker frees inside it: on 2026-10-12 the prunes
# alone left ~/.colima at 64.4 GB, and fstrim took it to 9.2 GB.
# Volumes are listed rather than pruned: they hold Dev Container gcloud logins
# and uv caches, and an orphaned one deserves a look before it goes.
colima-reclaim() {
    local before after reply
    colima status >/dev/null 2>&1 || { echo "Colima is not running (colima start)" >&2; return 1; }
    before=$(du -sk ~/.colima | cut -f1)
    docker system df
    printf '\nPrune stopped containers, unused images and build cache? [y/N] '
    read -r reply
    case "$reply" in
        [yY]*) ;;
        *) echo "Nothing pruned."; return 0 ;;
    esac
    docker container prune -f
    docker image prune -a -f
    docker builder prune -f
    colima ssh -- sudo fstrim -v /var/lib/docker
    after=$(du -sk ~/.colima | cut -f1)
    awk -v b="$before" -v a="$after" 'BEGIN { printf "\n~/.colima: %.1f GB -> %.1f GB\n", b / 1e6, a / 1e6 }'
    echo "Volumes no container uses (review, then docker volume rm):"
    docker volume ls --filter dangling=true --format '  {{.Name}}'
}
