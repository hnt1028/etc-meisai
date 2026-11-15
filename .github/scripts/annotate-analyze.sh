#!/usr/bin/env bash
# Convert `flutter analyze` output lines into GitHub annotation commands.
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*(error|warning|info)[[:space:]]+(•|-)[[:space:]]+(.*)[[:space:]]+(•|-)[[:space:]]+([^[:space:]]+):([0-9]+):([0-9]+)[[:space:]]+(•|-)[[:space:]]+([a-z_]+)$ ]]; then
    case "${BASH_REMATCH[1]}" in
      error) level=error ;;
      warning) level=warning ;;
      *) level=notice ;;
    esac
    echo "::${level} file=${BASH_REMATCH[5]},line=${BASH_REMATCH[6]},col=${BASH_REMATCH[7]},title=${BASH_REMATCH[9]}::${BASH_REMATCH[3]}"
  fi
done < "$1"
