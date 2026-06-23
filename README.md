# fffrag

FAT folder-first defragmentation to position directories at low cluster positions.

# Why?

Some Spreadstrum SoCs in feature phones have a firmware bug when reading FAT filesystems which prevents them from reading a directory if it appears at too large of a sector number. The device may show "Empty folder", even when the directory is populated. Duplicating a working directory will still result in this error, because the sector number is too large. Files, however, are unaffected. Therefore, we must allocate the directory structures first, and then copy the files after. This results in small sector numbers for the directories.

# Usage

## fffrag

Defragment and reorganize the FAT structure to position directories at the beginning of the FAT table.

Usage: `fffrag.sh /dev/sdX1`

## fffcopy

Recursively copy a directory from the host system to the FAT device, directories first.

Usage: `source fffrag.sh && fffcopy /dev/sdX1 /path/to/source/dir/`

## fffvalidate

Print the FAT cluster and sector numbers for the final filesystem.

Usage: `source fffrag.sh && fffvalidate /dev/sdX1`
