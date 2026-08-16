#!/usr/bin/env bash
# What is in this codebase, and what has anybody looked at twice?
#
# Not a quality metric. It is a list of places to point attention, built from
# two facts git already knows: how big a file is, and how many times anyone has
# come back to it. See Chapter 20.
set -euo pipefail
cd "$(dirname "$0")/.."

printf "%-34s %7s %8s %s\n" "FILE" "LINES" "COMMITS" "TESTED"
printf "%-34s %7s %8s %s\n" "----" "-----" "-------" "------"

total=0
once=0
for file in $(git ls-files "ios/Sources/*.swift" | sort); do
    lines=$(wc -l < "$file" | tr -d ' ')
    commits=$(git log --oneline -- "$file" | wc -l | tr -d ' ')

    # Does any test mention a type declared in this file?
    #
    # The first version of this matched on the filename, which reported
    # DeckStorage.swift as untested: the tests use FileDeckStorage, and
    # "\bDeckStorage\b" does not match inside it. Searching for the types the
    # file actually declares is barely more code and is not a lie.
    # Any leading modifiers, then the keyword, then the name. The first
    # attempt anchored on "^(public )?(struct|class|...)" and missed
    # "final class DeckStore", reporting a heavily tested file as untested.
    # Two false answers from one shortcut, in ten lines of shell.
    tested="NO"
    while read -r type; do
        [ -z "$type" ] && continue
        if git grep -q "\b$type\b" -- "ios/Tests/*.swift" 2>/dev/null; then
            tested="yes"; break
        fi
    done <<EOF
$(grep -oE "^[a-z ]*(struct|class|enum|protocol|actor) [A-Za-z0-9_]+" "$file" \
    | awk "{print \$NF}")
EOF

    flag=""
    if [ "$commits" -le 1 ] && [ "$tested" = "NO" ]; then flag="  <-- look here"; fi

    printf "%-34s %7s %8s %-6s%s\n" "${file#ios/}" "$lines" "$commits" "$tested" "$flag"
    total=$((total + lines))
    [ "$commits" -le 1 ] && once=$((once + lines))
done

echo
echo "  $total lines of source"
echo "  $once of them in files nobody has come back to"
echo
echo "Flagged files have no test and have never been revisited. That does not"
echo "mean they are wrong. It means nothing has ever forced anyone to read them."
