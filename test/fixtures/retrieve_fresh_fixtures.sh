#!/bin/sh

U_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.71 Safari/537.36"

get_page() {
  OUT=$1
  URL=$2
  wget -O "$OUT" --remote-encoding=utf-8 --user-agent="$U_AGENT" "$URL"
}

get_page "good_search.html" "http://na.finalfantasyxiv.com/lodestone/character?q=Krin%20Starrion&worldname=Gilgamesh" 
get_page "bad_search_no_player.html"  "http://na.finalfantasyxiv.com/lodestone/character?q=Goobly%20Gook&worldname=Gilgamesh"
get_page "bad_search_multiple_player.html"  "http://na.finalfantasyxiv.com/lodestone/character/?q=Gobble%20Gobble&worldname=Gilgamesh"
get_page "character_page_all_the_stuff.html"  "http://na.finalfantasyxiv.com/lodestone/character/6128486/"
get_page "character_page_no_stuff.html"  "http://na.finalfantasyxiv.com/lodestone/character/15893891/"
get_page "404.html"  "http://na.finalfantasyxiv.com/lodestone/character/123456789123456789/"
get_page "free_company.html" "http://na.finalfantasyxiv.com/lodestone/freecompany/9232238498621162014/"
get_page "fc_good_search.html" "http://na.finalfantasyxiv.com/lodestone/freecompany/?q=Magitaint%20Mayhem&worldname=Gilgamesh"
get_page "fc_bad_search.html" "http://na.finalfantasyxiv.com/lodestone/freecompany/?q=Well%20Crap&worldname=Gilgamesh"

for x in $(seq -w 01 30); do
  get_page "achievement_page_$x.html" "http://na.finalfantasyxiv.com/lodestone/character/6128486/achievement/?page=$x&filter=2"
done

for x in $(seq -w 01 12); do
  get_page "fc_member_page_$x.html" "http://na.finalfantasyxiv.com/lodestone/freecompany/9232238498621162014/member/?page=$x"
done
