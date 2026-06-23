#!/usr/bin/env bash

function fffvalidate() {
    local disk="$1"

    local mountpoint
    mountpoint="$(lsblk -no MOUNTPOINT "$disk")"

    while read -r dir; do
        relpath="${dir#"$mountpoint"}"
        relpath="${relpath:-/}"
        echo "$relpath"
        sudo fatcat "$disk" -l "$relpath" | grep "c="
    done < <(find "$mountpoint" -type d)
}

function fffcopy() {
    local disk="$1"
    local source="$2"

    local mountpoint
    mountpoint="$(lsblk -no MOUNTPOINT "$disk")"

    # Recreate FAT filesystem.
    sudo umount "$disk"
    sudo mkfs.fat -F 32 "$disk"

    # Reestablish mountpoint.
    sudo mkdir -p "$mountpoint"
    sudo mount "$disk" "$mountpoint"

    # Copy over directories.
    local reldir
    local destdir
    while read -r dir; do
        reldir="${dir#"$source"}"
        destdir="$mountpoint/$reldir"

        # Create low-sector positioned directory.
        sudo mkdir -p "$destdir"
    done < <(find "$source" -mindepth 1 -type d | sort)

    # Copy the files from source.
    sudo rsync -rlhv "$source/" "$mountpoint/"

    # Validate.
    fffvalidate "$disk"
}

function fffrag() {
    local disk="$1"
    local tmpdir
    tmpdir="$(mktemp -d tmp.XXXXXX)"

    local mountpoint
    mountpoint="$(lsblk -no MOUNTPOINT "$disk")"

    # Move to local temp folder.
    rsync -avh --remove-source-files "$mountpoint/" "$tmpdir/"

    # Recreate FAT filesystem.
    sudo umount "$disk"
    sudo mkfs.fat -F 32 "$disk"

    # Reestablish mountpoint.
    sudo mkdir -p "$mountpoint"
    sudo mount "$disk" "$mountpoint"

    # Copy over directories.
    local reldir
    local destdir
    while read -r dir; do
        reldir="${dir#"$tmpdir"}"
        destdir="$mountpoint/$reldir"

        # Create low-sector positioned directory.
        sudo mkdir -p "$destdir"
    done < <(find "$tmpdir" -mindepth 1 -type d | sort)

    # Copy the files back.
    sudo rsync -rlhv "$tmpdir/" "$mountpoint/"

    # Clean up temp folder.
    rm -rf "$tmpdir"

    # Validate.
    fffvalidate "$disk"
}

function main() {
    local disk="$1"
    
    if [[ -z "$disk" ]]; then
        echo "Incorrect usage."
        exit 1
    fi

    if [[ ! -b "$disk" ]]; then
        echo "$disk is not a valid disk."
        exit 1
    fi

    local mountpoint
    mountpoint="$(lsblk -no MOUNTPOINT "$disk")"
    if [[ -z "$mountpoint" ]]; then
        echo "$disk has no valid mountpoint."
        exit 1
    fi

    echo "DISK:          $disk"
    echo "MOUNTPOINT:    $mountpoint"
    echo

    local ok
    echo "WARNING: $disk will be COMPLETELY erased!"
    read -rn 1 -p "Proceed [yn]:" ok
    echo

    if [[ "$ok" != "y" ]]; then
        echo "Exiting."
        exit 1
    fi

    # Execute.
    fffrag "$disk"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    [[ $EUID -ne 0 ]] && exec sudo "$0" "$@"
    main "$@"
fi