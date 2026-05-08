#!/bin/bash
# Usage: ./set-title 2.0.9-loop

TAG="$1"

if [ -z "$TAG" ]; then
    echo "Usage: $0 <tagname>"
    exit 1
fi

# 1. Delete any old tag with the same base name that might override it
git tag -d "$TAG" 2>/dev/null
git push origin :refs/tags/"$TAG" 2>/dev/null

# 2. Delete the old base tag if it conflicts alphabetically
# Example: if TAG=2.0.9-loop, delete 2.0.9
BASE="${TAG%%-*}"
git tag -d "$BASE" 2>/dev/null
git push origin :refs/tags/"$BASE" 2>/dev/null

# 3. Create a fresh annotated tag on HEAD
git tag -a "$TAG" -m "Version override" HEAD

# 4. Push it
git push -f origin "$TAG"

# 5. Show what git describe will now return
echo -n "git describe → "
git describe --dirty --always --tags
