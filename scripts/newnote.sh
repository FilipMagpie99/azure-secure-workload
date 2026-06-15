#!/usr/bin/env bash
set -euo pipefail

# Usage: newnote <day> "<topic>"
DAY="${1:?Usage: newnote <day> \"<topic>\"}"
TOPIC="${2:?Usage: newnote <day> \"<topic>\"}"

# Derive repo root from the script's OWN location, so it works from anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
NOTES_DIR="$REPO_ROOT/notes"
mkdir -p "$NOTES_DIR"

# Clean filename: lowercase, spaces->hyphens, strip junk, squeeze repeats
SLUG="$(printf '%s' "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | tr -s '-')"
FILE="$NOTES_DIR/day${DAY}-${SLUG}.md"

if [[ -e "$FILE" ]]; then
  echo "⚠️  $FILE already exists — opening it."
else
  printf '# Day %s — %s\n\n' "$DAY" "$TOPIC" > "$FILE"
  cat >> "$FILE" <<'EOF'
## Cheat sheet
```bash
# az ...
```

## Notes
- 

## 💡 Gotchas
- 
EOF
  echo "✅ Created $FILE"
fi

# Open in VS Code (falls back to macOS default if the `code` CLI isn't installed)
if command -v code >/dev/null 2>&1; then
  code "$FILE"
else
  open -a "Visual Studio Code" "$FILE" 2>/dev/null || open "$FILE"
fi
