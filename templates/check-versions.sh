#!/usr/bin/env bash
# Compares the versions pinned in .devcontainer/versions.json with the newest
# supported releases (endoflife.date, RubyGems, npm). Exits 1 and prints what is
# behind. Runs in CI weekly (.github/workflows/scheduled-checks.yml) and by hand.
# Needs curl and jq.
#
# A project that must stay on an older version on purpose (for example a hosting
# runtime that has not caught up) records why under "holds" in versions.json:
#   "holds": {"node": "Neon Functions only offers nodejs24"}
# A held version that is behind prints HOLD with the reason and does not fail the
# check; it still prints BEHIND once the hold is removed. The project should add its
# own check for when the hold can end, so the hold is not forgotten.
set -euo pipefail

versions_file="$(dirname "$0")/versions.json"
behind=0

newest_supported() { # product -> "cycle latest" of the newest supported release
  curl -fsS "https://endoflife.date/api/$1.json" |
    jq -r --arg today "$(date -u +%F)" \
      '[.[] | select(.eol == false or (.eol | type == "string" and . >= $today))][0] | "\(.cycle) \(.latest)"'
}

compare() { # key label pinned newest
  local hold
  hold="$(jq -r --arg k "$1" '.holds[$k] // empty' "$versions_file")"
  if [ "$3" = "$4" ]; then
    printf 'ok      %-8s %s\n' "$2" "$3"
  elif [ -n "$hold" ]; then
    printf 'HOLD    %-8s pinned %s, newest supported %s (%s)\n' "$2" "$3" "$4" "$hold"
  else
    printf 'BEHIND  %-8s pinned %s, newest supported %s\n' "$2" "$3" "$4"
    behind=1
  fi
}

pinned() { jq -r --arg k "$1" '.[$k] // empty' "$versions_file"; }

[ -z "$(pinned ruby)" ] || compare ruby ruby "$(pinned ruby)" "$(newest_supported ruby | cut -d' ' -f2)"
[ -z "$(pinned go)" ] || compare go go "$(pinned go)" "$(newest_supported go | cut -d' ' -f2)"
[ -z "$(pinned rails)" ] || compare rails rails "$(pinned rails)" \
  "$(curl -fsS https://rubygems.org/api/v1/versions/rails/latest.json | jq -r .version)"
if [ -n "$(pinned node)" ]; then
  newest_lts="$(curl -fsS https://endoflife.date/api/nodejs.json | jq -r --arg today "$(date -u +%F)" \
    '[.[] | select((.lts | type == "string") and .lts <= $today and (.eol == false or .eol >= $today))][0].cycle')"
  compare node "node(LTS)" "$(pinned node)" "$newest_lts"
fi
if [ -n "$(pinned lighthouse)" ]; then
  newest_lighthouse="$(curl -fsS https://registry.npmjs.org/lighthouse/latest | jq -er .version)"
  compare lighthouse lighthouse "$(pinned lighthouse)" "$newest_lighthouse"
fi

exit "$behind"
