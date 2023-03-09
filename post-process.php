<?php

require 'vendor/autoload.php';

$diff = file_get_contents($argv[1] . '.md');

preg_match_all('/ \| dev-\b(\w.*)\b ([0-9a-f]{7}) \| /', $diff, $matches);

if (count($matches[2]) === 0) {
    exit(0);
}

$lines = explode(PHP_EOL, $diff);
foreach ($matches[2] as $matchIndex => $sha) {
    foreach ($lines as $index => $contents) {
        if (strpos($contents, ' | 9999999-dev ' . $sha . ' | dev-' . $matches[1][$matchIndex] . ' ' . $sha . ' | ') !== false) {
            unset($lines[$index]);
        }
    }
}

$processedContents = implode(PHP_EOL, $lines);
if (strpos($processedContents, '[Compare]') === false) {
    $processedContents = '';
}

file_put_contents($argv[1] . '.md', $processedContents);
