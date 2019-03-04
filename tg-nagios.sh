#!/bin/bash

# To create a bot and get a token, talk with @BotFather (see: https://core.telegram.org/bots)
TOKEN='XX:YYYY' # botID : botSecretAuthToken
# set to False in production
SILENCE='False'
# set to False if you want a preview of web pages in the message
NOPREVIEW='True'
# set to either Markdown or HTML to allow formatting in messages (see: https://core.telegram.org/bots/api#sendmessage)
MODE='Markdown'

[ -z "${TOKEN}" ] && echo "Error: Telegram Bot Token is not defined" && exit 1

if [ $# -ne 6 ] ; then
    cat <<EOF
Missing paramater

Usage: 
 $0 host|service src ID HOSTNAME|SERVICENAME HOSTADDRESS|SERVICEDESC \"HOSTOUTPUT|SERVICEOUTPUT\"
 ID : recipient's ID, id < 0 -> group chat, id > 0 -> direct message to user
 the other arguments comme from Nagios

Example:
 $0 host myNagios -12345 someHost someIP \"PING OK - Packet loss = 0%, ...\"
 $0 service myNagios -12345 someService someHost \"service check output ...\"

EOF
    exit 1
fi

typ="$1"  # host or service
src="$2"  # source of the message (if you use one bot and one chat for all your nagios instances
to="$3"   # > 0 : user, < 0 : groupe, - 0 : error
name="$4" # host: hostname, service: description
desc="$5" # host: ip, service: hostname
output="$6"

[ -z "${to}" ] && echo "Error: Telegram User/Group ID is not defined" && exit 1
[ "${to}" == "0" ] && echo "Error: Telegram User/Group ID cannot be null/0" && exit 1


state="unknown"
echo "${output}" | grep -e "OK" -e "UP" &> /dev/null
[ $? -eq 0 ] && SILENCE='True' && state="*OK* ✅"
echo "${output}" | grep -e "KO" -e "CRITICAL" -e "DOWN" &> /dev/null
[ $? -eq 0 ] && SILENCE='False' && state="*CRITICAL* 🛑"
echo "${output}" | grep -e "WARNING" -ie "RECOVER" -ie '\[W\] ' &> /dev/null
[ $? -eq 0 ] && SILENCE='True' && state="_WARNING_"

if [ "${typ}" == "host" ] ; then
curl -s -o /dev/null -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
    -d chat_id=${to} \
    -d disable_notification=${SILENCE} -d disable_web_page_preview=${NOPREVIEW} \
    -d parse_mode=${MODE} \
    -d text="*${name//_/ }* (via _${src//_/ }_)
_${desc//_/ }_ : ${state//_/ }
\`\`\`
${output//_/ }
\`\`\`" &> /dev/null
elif [ "${typ}" == "service" ] ; then
curl -s -o /dev/null -X POST https://api.telegram.org/bot${TOKEN}/sendMessage \
    -d chat_id=${to} \
    -d disable_notification=${SILENCE} -d disable_web_page_preview=${NOPREVIEW} \
    -d parse_mode=${MODE} \
    -d text="*${desc//_/ }* (via _${src//_/ }_)
_${name//_/ }_ : ${state//_/ }
\`\`\`
${output//_/ }
\`\`\`" &> /dev/null

else
	echo "Error: unknown notification type (${typ})" && exit 1
fi

exit 0
# EOF
