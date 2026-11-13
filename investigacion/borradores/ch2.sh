#!/bin/bash
# usage: ch.sh CHANNEL_ID
export LC_ALL=C
id=$1
echo "##### $id"
for tab in shorts videos; do
  f=$(mktemp)
  yt-dlp -q --no-warnings --flat-playlist --print "%(id)s|%(title).70s|%(view_count)s" "https://www.youtube.com/channel/$id/$tab" 2>/dev/null > "$f"
  n=$(wc -l < "$f")
  [ "$n" = "0" ] && { echo "[$tab] none"; continue; }
  tot=$(awk -F'|' '{s+=$NF} END{print s}' "$f")
  med=$(awk -F'|' '{print $NF}' "$f" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
  echo "[$tab] n=$n total_views=$tot median=$med"
  sort -t'|' -k3 -n -r "$f" | head -6
  first=$(head -1 "$f" | cut -d'|' -f1); last=$(tail -1 "$f" | cut -d'|' -f1)
  for v in $first $last; do
    yt-dlp -q --no-warnings --skip-download --print "  date:%(upload_date)s subs:%(channel_follower_count)s ch:%(channel)s dur:%(duration)s lang:%(language)s | %(title).50s" "https://www.youtube.com/watch?v=$v" 2>/dev/null
  done
  # last 10 upload dates for cadence (shorts only)
  if [ "$tab" = "shorts" ]; then
    echo -n "  recent dates: "
    head -4 "$f" | cut -d'|' -f1 | while read v; do yt-dlp -q --no-warnings --skip-download --print "%(upload_date)s" "https://www.youtube.com/watch?v=$v" 2>/dev/null | tr '\n' ' '; done; echo
  fi
  rm "$f"
done
