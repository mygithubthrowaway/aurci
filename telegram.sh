#!/bin/bash
export LANG=C

TOKEN="$1"
CHATID="$2"
MESSAGE="$3"

MESSAGE="$(echo -e "<strong>Travis-ci Repo Notification</strong> ${MESSAGE} )"   
/usr/bin/curl --silent --output /dev/null \
    --data-urlencode "chat_id=${CHATID}" \
    --data-urlencode "text=${MESSAGE}" \
    --data-urlencode "parse_mode=HTML" \
    --data-urlencode "disable_web_page_preview=true" "https://api.telegram.org/bot${TOKEN}/sendMessage"
