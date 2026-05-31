#!/usr/bin/env bash
# Backup entries listed in <src_dir>/.backup.conf to <dest_dir>.
# Entries are globs relative to src_dir; destination layout mirrors that relative path.

set -euo pipefail
shopt -s nullglob dotglob

usage() {
    echo "Usage: $0 [--dry-run] <src_dir> <dest_dir>"
    echo
    echo "Reads <src_dir>/.backup.conf - one glob per line, relative to <src_dir>."
    echo "'#' comments and blank lines ignored."
    exit 1
}

dry_run=0
positional=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) dry_run=1; shift ;;
        -h|--help) usage ;;
        --) shift; positional+=("$@"); break ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) positional+=("$1"); shift ;;
    esac
done

[[ ${#positional[@]} -eq 2 ]] || usage
src_dir="${positional[0]%/}"
dest_dir="${positional[1]%/}"

[[ -d "$src_dir" ]] || { echo "Error: src_dir '$src_dir' is not a directory." >&2; exit 1; }
[[ -d "$dest_dir" ]] || { echo "Error: dest_dir '$dest_dir' is not a directory." >&2; exit 1; }
[[ -w "$dest_dir" ]] || { echo "Error: dest_dir '$dest_dir' is not writable." >&2; exit 1; }

config_file="$src_dir/.backup.conf"
[[ -r "$config_file" ]] || { echo "Error: config file '$config_file' not readable." >&2; exit 1; }

rsync_opts=(-aAX --delete --human-readable "--info=stats1,progress2")
(( dry_run )) && rsync_opts+=(--dry-run)

ok=0
fail=0
skipped=0

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line// }" || "$line" =~ ^[[:space:]]*# ]] && continue

    pattern="${line#"${line%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"
    pattern="${pattern#/}"

    mapfile -t matches < <(cd "$src_dir" && compgen -G "$pattern" || true)
    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "⚠️  No matches for: $line" >&2
        skipped=$((skipped + 1))
        continue
    fi

    for rel in "${matches[@]}"; do
        src="$src_dir/$rel"
        dest="$dest_dir/$rel"

        if [[ ! -e "$src" ]]; then
            echo "⚠️  Skip (missing): $src" >&2
            skipped=$((skipped + 1))
            continue
        fi

        echo "📦 $rel"
        mkdir -p -- "$(dirname -- "$dest")"

        if rsync "${rsync_opts[@]}" -- "${src%/}/" "${dest%/}/"; then
            ok=$((ok + 1))
        else
            echo "❌ rsync failed for $rel" >&2
            fail=$((fail + 1))
        fi
    done
done < "$config_file"

echo
echo "Summary: $ok ok, $fail failed, $skipped skipped$([[ $dry_run -eq 1 ]] && echo ' (dry-run)')"
(( fail == 0 )) || exit 1
