<?php

function sortCal($e, $f)
{
	if ($e['start'] < $f['start'])
		return -1;
	if ($e['start'] == $f['start'])
		return 0;
	if ($e['start'] > $f['start'])
		return 1;
}

function findCurrent($c)
{
	$n = getdate()[0];
	foreach($c as $e)
	{
		if (($n > $e['start']) and ($n <= $e['end']))
		{
			return $e;
		}
	}
	return FALSE;
}

function parseIcal()
{
	$CALENDARURL = 'https://url/to/calendar.ics';
	$eUid   = "";
	$eStart = "";
	$eEnd   = "";
	$eSum   = "";
	$eDesc  = "";
	$cal = array();
	$fh = @fopen($CALENDARURL, 'r');
	if (!$fh)
		return $cal;
	while ($l = fgets($fh))
	{
		if (preg_match("/^BEGIN:VEVENT.*$/", $l))
		{
			continue;
		}
		elseif (preg_match("/^END:VEVENT.*$/", $l))
		{
			if ($eDesc == "oncall")
				$cal[] = array('start' => $eStart, 'end' => $eEnd, 'sum' => $eSum, 'desc' => $eDesc);
			$eUid   = "";
			$eStart = "";
			$eEnd   = "";
			$eSum   = "";
			$eDesc  = "";
		}
		else
		{
			if (preg_match("/^DTSTART:(.*)$/", $l, $s))
				$eStart = strtotime($s[1]);
			if (preg_match("/^DTEND:(.*)$/", $l, $e))
				$eEnd = strtotime($e[1]);
			if (preg_match("/^UID:(.*)$/", $l, $u))
				$eUid = trim($u[1]);
			if (preg_match("/^SUMMARY:(.*)$/", $l, $r))
				$eSum = trim($r[1]);
			if (preg_match("/^DESCRIPTION:(.*)$/", $l, $c))
				$eDesc = trim($c[1]);
		}
	}
	@fclose($fh);

	usort($cal, 'sortCal');
	return findCurrent($cal);
}

$contacts = array(
	'member1' => '+CCAAAAAAAA',
	'member2' => '+CCBBBBBBBB',
	// ...
	'memberN' => '+CCZZZZZZZZ',
);

$cur = parseIcal();
$guy = strtolower($cur['sum']);
$cur['phone'] = $contacts[$guy];
?>
