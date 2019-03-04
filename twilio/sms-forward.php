<?php
/** Forward SMS received by a twilio phone number to a Telegram User/Group */

define('TG_TOKEN', 'XX:YYYY'); // botID : botSecretAuthToken
define('TG_URL', 'https://api.telegram.org/');


function forward_sms($from, $body)
{ // this part generate the TwinML used by Twilio to forward a SMS at the desired person
	include('cal.php'); // gets information about who is oncall/duty from an ICS calendar
	header("Content-Type: text/xml; charset=utf-8");
	$d = gmdate('N'); // 1:monday .. 7:sunday
	$h = gmdate('G'); // hour, without leading 0
	//$w = gmdate('I') == 0; // winter time
	// if saturday/sunday or time is not office hours (in UTC/GMT)
	if (($d > 6) || (($h < 7) && ($h > 16)))
	{
		echo <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
 <Message to='{$cur['phone']}'>from {$from}:
	{$body}</Message>
</Response>
XML;
	}
}

function forward_telegram($to, $from, $body, $intro)
{ // this forward the SMS received on a Twilio phone number to a given Telegram chat/group
	$TG_SEND_MSG = TG_URL . "bot" . TG_TOKEN . "/sendMessage";
	$encoded = "";
	$call_args = array(
		'chat_id' => $to,
		'disable_notification' => 'False',
		'disable_web_page_preview' => 'True',
		'parse_mode' => 'Markdown',
	);
	foreach($call_args as $a => $v) {
		$encoded .= urlencode($a)."=".urlencode($v)."&";
	}

	$message = "{$intro} {$from}:\n{$body}";
	$encoded .= "text=".urlencode($message);

	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $TG_SEND_MSG);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
	curl_setopt($ch, CURLOPT_HEADER, FALSE);
	curl_setopt($ch, CURLOPT_POST, TRUE);
	curl_setopt($ch, CURLOPT_POSTFIELDS,  $encoded);
	$out = curl_exec($ch);
	curl_close($ch);
}

$TO = '1234567890'; # Someone's Telegram User ID
#$TO = '-0987654321'; # Id to some Telegram groupchat
$start = "📨 from ";
forward_sms($_REQUEST['From'], $_REQUEST['Body']);
forward_telegram($TO, $_REQUEST['From'], $_REQUEST['Body'], $start);

exit(0);
?>
