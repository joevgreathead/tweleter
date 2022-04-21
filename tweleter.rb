require 'json'
require 'time'
require 'twitter'

def clean_list(list)
  list&.split(",").map(&:strip).map(&:downcase)
end

def env(key, default = nil)
  raise "Missing env variable [#{key}]. Tweleter can not run without this." if ENV[key].nil? && default.nil?
  ENV[key] || default
end

def to_bool(val)
  val.to_s == "true"
end

EXCLUDE_TWEET_IDS = clean_list(env("EXCLUDE_IDS", ""))
raise "EXCLUDE_IDS must be a comma separated list." unless EXCLUDE_TWEET_IDS.is_a? Array

EXCLUDE_TEXT_VALS = clean_list(env("EXCLUDE_TEXT", ""))
raise "EXCLUDE_IDS must be a comma separated list." unless EXCLUDE_TEXT_VALS.is_a? Array

DESTROY_ENDPOINT = "https://api.twitter.com/1.1/statuses/destroy/"

LIVE                = to_bool(env "REAL_DELETES", false)
VERBOSE             = to_bool(env "VERBOSE", true)
WAIT_BETWEEN        = env("BETWEEN", 43_200).to_i # default is 12hrs

API_KEY             = env "API_KEY"
API_KEY_SECRET      = env "API_KEY_SECRET"
ACCESS_TOKEN        = env "ACCESS_TOKEN"
ACCESS_TOKEN_SECRET = env "ACCESS_TOKEN_SECRET"

DAYS_OLD            = env("DELETE_UP_TO_DAYS_AGO", 180).to_i
TWITTER_USER        = env "TWITTER_USER"
LIKES_THRESHOLD     = env "MIN_LIKES", 10

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = API_KEY
  config.consumer_secret     = API_KEY_SECRET
  config.access_token        = ACCESS_TOKEN
  config.access_token_secret = ACCESS_TOKEN_SECRET
end

SEP = "*" * 50
DAY_IN_SECONDS = 86_400

def link_to(id)
  "https://twitter.com/#{TWITTER_USER}/status/#{id}"
end

def delete?(t)
  delete_window_starts = Time.now.to_i - (DAY_IN_SECONDS * DAYS_OLD)

  id = t.id
  text = t.full_text.downcase
  likes = t.favorite_count.to_i
  created_at = t.created_at.to_i

  include_text = EXCLUDE_TEXT_VALS.any? { |ti| text.include?(ti) }
  include_id = EXCLUDE_TWEET_IDS.include?(id)
  have_many_likes = likes >= LIKES_THRESHOLD
  old_enough_to_delete = created_at <= delete_window_starts

  !include_text && !include_id && !have_many_likes && old_enough_to_delete
end

puts SEP
puts """
Tweleter is configured as follows:
  - Tweets older than #{DAYS_OLD} will be deleted if queryable
  - The account having tweets deleted is: #{TWITTER_USER}

  Warning: Please ensure the tokens and secrets configured are for the above mentioned username
  Warning: Twitter's API generally allows paging back ~3,200 tweets. If there are tweets farther back than that, then this process will not delete them
  Warning: This is built on Twitter's 1.1 API. There is no guarantee this will continue working in the future

Tweets containing the following normalized text values will not be deleted:
#{EXCLUDE_TEXT_VALS.map { |txt| "[#{txt}]" }.join("\n")}
Excluded tweet IDs include:
#{EXCLUDE_TWEET_IDS.map { |id| link_to(id) }.join("\n")}
"""
puts SEP

puts "Getting some tweets..."

total = 0

while true do
  max_id = nil
  while true do
    options = {
      count: 200,
      include_rts: true,
    }
    options[:max_id] = max_id if max_id
    resp = client.user_timeline(TWITTER_USER, options)

    resp.each do |tweet|
      total += 1
      if delete?(tweet)
        puts "WOULD DELETE | #{link_to(tweet.id)}" if VERBOSE
        client.destroy_status(tweet.id) if LIVE
      else
        puts "IGNORE       | #{link_to(tweet.id)}" if VERBOSE
      end
    end

    break if resp.last.nil? || resp.last.id == max_id
    max_id = resp.last.id - 1

    puts "Found new max id of #{link_to(max_id)}" if VERBOSE
  end

  puts "Took all possible actions. Sleeping for #{WAIT_BETWEEN} seconds..."
  sleep(WAIT_BETWEEN)
end