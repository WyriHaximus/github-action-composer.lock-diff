<?php

require '/workdir/vendor/autoload.php';

$diff = file_get_contents('/workdir/' . $argv[1] . '.md');
$prNumber = json_decode(file_get_contents(getenv('GITHUB_EVENT_PATH')), true)['pull_request']['number'];
$locator = '<!-- @)}---^----- wyrihaximus/github-action-composer.lock-diff ' . getenv('GITHUB_WORKFLOW') . ' __/<+>\__ ' . $argv[1] . ' -----^---{(@ -->';
$commentContents = $locator . PHP_EOL . $argv[2] . PHP_EOL . $diff . PHP_EOL;

$client = new GuzzleHttp\Client();
$res = $client->request('GET', 'https://api.github.com/repos/' . getenv('GITHUB_REPOSITORY') . '/issues/' . $prNumber . '/comments', [
    'headers' => [
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => 'token ' . getenv('GITHUB_TOKEN'),
    ],
]);
$comments = json_decode($res->getBody()->getContents(), true);

foreach ($comments as $comment) {
    if (strpos($comment['body'], $locator) === 0) {
        if (strlen($diff) === 0) {
            echo 'Deleting ', $argv[1], ' comment', PHP_EOL;
            $client->request('DELETE', 'https://api.github.com/repos/' . getenv('GITHUB_REPOSITORY') . '/issues/comments/' . $comment['id'], [
                'headers' => [
                    'Accept' => 'application/vnd.github.v3+json',
                    'Authorization' => 'token ' . getenv('GITHUB_TOKEN'),
                ],
            ]);

            exit(0);
        }

        echo 'Updating ', $argv[1], ' comment', PHP_EOL;
        $client->request('PATCH', 'https://api.github.com/repos/' . getenv('GITHUB_REPOSITORY') . '/issues/comments/' . $comment['id'], [
            'headers' => [
                'Accept' => 'application/vnd.github.v3+json',
                'Authorization' => 'token ' . getenv('GITHUB_TOKEN'),
                'Content-type' => 'application/json',
            ],
            'json' => ['body' => $commentContents],
        ]);

        exit(0);
    }
}

if (strlen($diff) === 0) {
    exit(0);
}


echo 'Posting ', $argv[1], ' comment', PHP_EOL;
$client->request('POST', 'https://api.github.com/repos/' . getenv('GITHUB_REPOSITORY') . '/issues/' . $prNumber . '/comments', [
    'headers' => [
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => 'token ' . getenv('GITHUB_TOKEN'),
        'Content-type' => 'application/json',
    ],
    'json' => ['body' => $commentContents],
]);
