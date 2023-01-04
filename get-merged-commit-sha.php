<?php

$json = json_decode(file_get_contents(getenv('GITHUB_EVENT_PATH')));

if (property_exists($json, 'merge_commit_sha')) {
    echo $json->merge_commit_sha;
    exit(0);
}

echo $json->pull_request->merge_commit_sha;
