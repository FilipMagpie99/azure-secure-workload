# Day 12 — github workflow

git checkout main && git pull        # start: świeży main
git checkout -b temat           # branch roboczy
# ...praca, commity punktami kontrolnymi...
git push -u origin temat        # branch na GitHub
gh pr create --title "..." --body "..."
gh pr checks --watch                 # czekaj na pipeline
gh pr merge --squash --delete-branch # gdy zielono i plan OK
git checkout main && git pull        # wróć na świeży main