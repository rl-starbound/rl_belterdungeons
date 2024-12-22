#!/bin/sh

set -eu

if [ ! -f _metadata ]; then
  echo 'ERROR: not in mod root. Aborting.' >&2
  exit 1
fi

mkdir "/tmp/vl-$(id -u)-$$"
trap 'rm -fr "/tmp/vl-$(id -u)-$$"'  EXIT

find dungeons -iname "*.json" -exec grep '\\"locationType\\"' {} \; | grep -v '\\"rl_questLocation\\"' | sed 's/^[[:space:]]*"value"[[:space:]]*:[[:space:]]*"{[[:space:]]*\\"locationType\\"[[:space:]]*:[[:space:]]*\\"\(.*\)\\"[[:space:]]*}"/\1/' >"/tmp/vl-$(id -u)-$$/dungeon_locations.txt"
find dungeons -iname "*.json" -exec grep '\\"locationType\\"' {} \; | grep '\\"rl_questLocation\\"' | sed 's/^[[:space:]]*"value"[[:space:]]*:[[:space:]]*".*\\"locationType\\"[[:space:]]*:[[:space:]]*\\"\([^"]*\)\\".*"/\1/' >>"/tmp/vl-$(id -u)-$$/dungeon_locations.txt"
sort "/tmp/vl-$(id -u)-$$/dungeon_locations.txt" | uniq >"/tmp/vl-$(id -u)-$$/unique-dungeon_locations.txt"

strip-json-comments quests/generated/locations.config.patch | jq -r '.[] | (.path + "." + (.value | keys | .[]))' | sed 's|^/\(.*\)|\1|' | sort >"/tmp/vl-$(id -u)-$$/quest_locations.txt"

diff -u --color=auto "/tmp/vl-$(id -u)-$$/unique-dungeon_locations.txt" "/tmp/vl-$(id -u)-$$/quest_locations.txt"
