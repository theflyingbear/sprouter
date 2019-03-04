<?php /** script used to sent SMS from Telegram to Twilio */

define('TW_URL', 'https://api.twilio.com');
define('TW_SID', 'XXXX'); # Twilio Account SID
define('TW_TOKEN', 'YYYY'); # Twilio Account Token
define('TW_SENDER', '+CCNNNNNNNN'); # Active Twilio number linked to the same account as TW_SID

define('TG_URL', 'https://api.telegram.org');
define('TG_TOKEN', 'XX:YYYY'); // botID : botSecretAuthToken

function send_twilio($to, $from, $body)
{ // send a SMS to someone via twilio, presenting a given twilio number as the sender
	$TW_SEND_TEXT = TW_URL . "/2010-04-01/Accounts/" . TW_SID . "/Messages";
	$msg = array(
		'From' => $from,
		'To' => $to,
		'Body' => $body
	);
	$encoded = "";
	foreach($msg as $k => $v) {
		$encoded .= $k."=".urlencode($v).'&';
	}
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, $TW_SEND_TEXT);
	curl_setopt($ch, CURLOPT_USERPWD, TW_SID . ":" . TW_TOKEN );
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
	curl_setopt($ch, CURLOPT_HEADER, FALSE);
	curl_setopt($ch, CURLOPT_POST, TRUE);
	curl_setopt($ch, CURLOPT_POSTFIELDS,  trim($encoded, '&'));
	$out = curl_exec($ch);
	curl_close($ch);
	return '```'. $encoded . "\n". print_r($out, TRUE) . '```';
}

define ('url', TG_URL . "/bot". TG_TOKEN . "/");
$update = json_decode(file_get_contents('php://input') ,true); # gets the data sent to the bot
$chat_id = $update['message']['chat']['id']; // Telegram chat id
$name = $update['message']['from']['first_name']; // Telegram user who sent the data

if (preg_match("/^\/text ([+][0-9]+) (.+)$/", $update['message']['text'], $m))
{ // if message is the "/text" command withe required arguments (phone number w/ format +CCNNNNNNNN and message body)
	$o = send_twilio($m[1], TW_SENDER, $m[2]);
	$message = urlencode("sending '{$m[2]}' to *{$m[1]}* on behalf of {$name}/" . TW_SENDER . "\n"); # . $o . "\n");
	file_get_contents(url . "sendmessage?text=" . $message . "&chat_id=" . $chat_id . "&parse_mode=Markdown");
}

?>
