#!/bin/bash


# To create a bot and get a token, talk with @BotFather (see: https://core.telegram.org/bots)
TOKEN='XX:YYYY' # botID : botSecretAuthToken
# set to False in production - if you want it
SIL='True'
# set to False if you want a preview of web pages in the message
NOPREVIEW='True'
# set to either Markdown or HTML to allow formatting in messages (see: https://core.telegram.org/bots/api#sendmessage)
MODE='HTML'

[ -z "${TOKEN}" ] && echo "Error: Telegram Bot Token is not defined" && exit 1

function usage {
    cat <<EOF
Missing paramater

Usage:
 $0 [-h] -x host|service 
 -4 address IPv4 
 -6 address IPv6
 -b author
 -c comment
 -d date
 -f from
 -i icinga URL
 -l hostname
 -n hostname displayname
 -o host or service output
 -r user ID -- recipient's ID, id < 0 -> group chat, id > 0 -> direct message to user
 -s host or service state (Up/Down or OK/Warning/Critical/Unknown)
 -t notification type (DowntimeStart/DowntimeEnd/DowntimeRemoved/Custom/Acknowledgement/Problem/Recovery/FlappingStart/FlappingEnd)
 -e service name?
 -u service displayname << only for service
-v log to syslog

-h show help
-x what kind of notification is that

EOF

#Example:
# $0 host myNagios -12345 someHost someIP \"PING OK - Packet loss = 0%, ...\"
# $0 service myNagios -12345 someService someHost \"service check output ...\"
#
#EOF
}

typ=""
addr4=""
addr6=""
addr=""
author=""
comment=""
ndate=""
from=""
nurl=""
name=""
lname=""
output=""
to=""
state=""
ntype=""
desc=""
svce=""

while getopts 'x:4:6:b:c:d:f:i:l:n:o:r:s:t:u:e:vh' OPTION
do
case "$OPTION" in
    x)
        typ="${OPTARG}"
        ;;

    4)
        addr4="${OPTARG}"
        ;;
    6)
        addr6="${OPTARG}"
        ;;
    b)
        author="${OPTARG}"
        ;;
    c)
        comment="${OPTARG}"
        ;;
    d)
        ndate="${OPTARG}"
        ;;
    f)
        from="${OPTARG}"
        ;;
    i)
        nurl="${OPTARG}"
        ;;
    l)
        name="${OPTARG}"
        ;;
    n)
        lname="${OPTARG}"
        ;;
    o)
        output="${OPTARG}"
        ;;
    r)
        to="${OPTARG}"
        ;;
    s)
        state="${OPTARG}"
        ;;
    t)
        ntype="${OPTARG}"
        ;;
    u)
        desc="${OPTARG}"
        ;;
    v)  # unused
        ;;
    e)
        svce="${OPTARG}"
        ;;
    h)
        usage
        exit 0
        ;;
    *) # ignore unknown args
        ;;
esac
done

#[ "${typ}" == "" ] && usage && exit 1
#[ "${to}" == "" ] && usage && exit 1
#[ "${name}" == "" ] && usage && exit 1
#[ "${desc}" == "" ] && usage && exit 1
#[ "${output}" == "" ] && usage && exit 1

[ "${to}" == "0" ] && echo "Error: Telegram User/Group ID cannot be null/0" && exit 1

case ${state,,} in
up)
    #SILENCE="${SIL:-True}"
    state="🍀"
    ;;
ok)
    #SILENCE="${SIL:-True}"
    state="✅"
    ;;
down)
    #SILENCE="${SIL:-False}"
    state="🚫"
    ;;
critical)
    #SILENCE="${SIL:-False}"
    state="💥"
    ;;
warning)
    #SILENCE=${SIL:-True}
    state="⚠"
    ;;
unknown)
    #SILENCE=${SIL:-True}
    state="🧞"
    ;;
*)
    #SILENCE=${SIL:-True}
    state="🧚"
    ;;
esac

case ${ntype,,} in
acknowledgement)
    state="${state} ✔"
    ;;
problem)
    state="${state} ⭕"
    ;;
recovery)
    state="${state} ♻"
    ;;
flapping*)
    state="${state} ➰"
    ;;
downtime*)
    state="${state} 〽"
    ;;
custom*)
    state="${state} 📨"
    ;;
*)
    state="${state} ${ntype}"
    ;;
esac

[ -n "${addr4}" ] && addr="${addr} ${addr4}"
[ -n "${addr6}" ] && addr="${addr} ${addr6}"

extra=""
if [ -n "${comment}" ]; then
    extra="
---- 
From: <a href=\"mailto:${from:-none}\">${author:-unknown}</a>
Date: ${ndate:-today}
${comment}"
fi
#if [ "${typ}" == "service" ] ; then
#    extra="${extra}
#---- debug: ----
#called: <code>$0 $*</code>
#name=${name} / lname=${lname}
#addr=${addr}
#svce=${svce} / desc=${desc}"
#fi

dede=$(date +%u)
deho=$(date +%k | tr -d ' ')

if [ ${dede} -ge 6 ] ; then
    SILENCE='True'
elif [ ${deho} -lt 9 ] && [ ${deho} -ge 20 ] ; then
    SILENCE='True'
else
    SILENCE='False'
fi

if [ "${typ}" == "host" ] ; then
    curl -s -o /dev/null -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
      -d chat_id=${to} \
      -d disable_notification=${SILENCE} -d disable_web_page_preview=${NOPREVIEW} \
      -d parse_mode=${MODE} \
      -d text="<a href=\"${nurl}\">${name}</a>
<i>${lname}</i> : ${state}
<pre>${output}</pre>${extra}" &> /dev/null
elif [ "${typ}" == "service" ] ; then
    #curl -v -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
    curl -s -o /dev/null -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
    -d chat_id=${to} \
    -d disable_notification=${SILENCE} -d disable_web_page_preview=${NOPREVIEW} \
    -d parse_mode=${MODE} \
    -d text="<a href=\"${nurl}\">${name} / ${desc}</a>: ${state}
<pre>${output}</pre>${extra}" &> /dev/null
#<pre>${output}</pre>${extra}" | json_pp

else
 echo "Error: unknown notification type (${typ})" && exit 1
fi

exit 0

# EOF
