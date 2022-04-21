# Tweleter

A simple tool to auto-delete tweets as time goes on.

Run as a [Docker image](https://hub.docker.com/r/joevgreathead/tweleter) and include the following env variables to configure its function:

## App Configuration

`REAL_DELETES`
default: false
Set to "true" to actually delete Tweets. Otherwise, logs will record which tweets would get deleted or not.

`VERBOSE`
default: true
When true, messages for each tweet and whether they would be deleted are logged.

`BETWEEN`
default: 43200 (12 hrs)
How long to wait between runs in seconds. 

## API Configuration

`API_KEY`
`API_KEY_SECRET`
`ACCESS_TOKEN`
`ACCESS_TOKEN_SECRET`
To use this, you'll need a simple, free app from dev.twitter.com. Get these credentials for the username configured below.

`TWITTER_USER`
The username for the twitter account attached to the above secrets.

## Tweet Deletion Filtering

`DELETE_UP_TO_DAYS_AGO`
default: 180
How far back to begin deleting tweets. The default of 180 means no tweets in the last 180 days will be deleted, regardless of content.

`EXCLUDE_IDS`
A comma delimited list of tweet ids to ignore.

`EXCLUDE_TEXT`
A comma delimited list of keywords. Any tweets with these keywords will not be deleted. Must be lowercase.

`MIN_LIKES`
default: 10
The minimum number of likes a tweet needs to not get deleted.