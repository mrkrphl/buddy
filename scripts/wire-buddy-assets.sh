#!/usr/bin/env bash
set -euo pipefail
B="/Users/markraphaelsto.domingo/Projects/buddy"
A="$B/Buddy/Assets.xcassets"
CUR="/Users/markraphaelsto.domingo/.cursor/projects/Users-markraphaelsto-domingo-Projects/assets"

mkdir -p \
  "$A/BuddyFormBalanced.imageset" \
  "$A/BuddyFormHungry.imageset" \
  "$A/BuddyFormSoft.imageset" \
  "$A/BuddyFormStrong.imageset"

cp "$B/design/buddy-mascot-ghost-marshmallow.png" "$B/design/buddy-form-balanced.png"
cp "$CUR/buddy-form-hungry.png" "$B/design/buddy-form-hungry.png"
cp "$CUR/buddy-form-soft.png" "$B/design/buddy-form-soft.png"
cp "$CUR/buddy-form-strong.png" "$B/design/buddy-form-strong.png"

cp "$B/design/buddy-form-balanced.png" "$A/BuddyFormBalanced.imageset/BuddyFormBalanced.png"
cp "$B/design/buddy-form-hungry.png" "$A/BuddyFormHungry.imageset/BuddyFormHungry.png"
cp "$B/design/buddy-form-soft.png" "$A/BuddyFormSoft.imageset/BuddyFormSoft.png"
cp "$B/design/buddy-form-strong.png" "$A/BuddyFormStrong.imageset/BuddyFormStrong.png"
cp "$B/design/buddy-mascot-ghost-marshmallow.png" "$A/AppIcon.appiconset/AppIcon.png"

echo "Assets wired."
