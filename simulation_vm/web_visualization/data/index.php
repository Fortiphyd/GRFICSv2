<?php
$address = '127.0.0.1';
$port = 55555;

$fp = pfsockopen($address, $port, $errno, $errstr);
echo $errstr;
fwrite($fp, '{"request":"read"}\n');
echo fgets($fp, 1500);
?>

