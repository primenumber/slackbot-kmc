require 'slack'
require 'yaml'

config = YAML.load_file('config.yml')
SLACK_TOKEN = config['slack-token']
STATUS_CHANNEL = config['status-channel']

Slack.configure do |config|
  config.token = SLACK_TOKEN
end

Slack.auth_test


client = Slack.realtime

client.on :hello do
  puts 'Successfully connected.'
  params = {
    token: SLACK_TOKEN,
    channel: STATUS_CHANNEL,
    username: 'poyo',
    text: 'good morning.',
    icon_emoji: ':poyo:'
  }
  Slack.chat_postMessage params
end

client.on :close do
  puts 'Client is about to disconnect.'
  params = {
    token: SLACK_TOKEN,
    channel: STATUS_CHANNEL,
    username: 'poyo',
    text: 'good bye.',
    icon_emoji: ':poyo:'
  }
  Slack.chat_postMessage params
end

def get_command(text)
  text.strip.split(" ")
end

def fortune(channel, args)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: 'fortune(6)',
    text: `fortune`,
    icon_emoji: ':sparkles:'
  }
  Slack.chat_postMessage params
end

def help(channel, args)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: 'help',
    text: 'help me',
    icon_emoji: ':sos:'
  }
  Slack.chat_postMessage params
end

def slot_text
  items = ['3', '3fear', '3guru', '3null', 'tangerine', 'fish']
  ary = 3.times.map {|i| ":#{items.sample}:"}
  result = ary.join("")
  if ary.uniq.length == 1 then
    return result + ":5000chouen:"
  else
    return result
  end
end

def slot(channel)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: 'slot machine',
    text: slot_text,
    icon_emoji: ':slot_machine:'
  }
  Slack.chat_postMessage params
end

def fake_slot(channel)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: '3',
    text: "ちがうよ",
    icon_emoji: ':3jito:'
  }
  Slack.chat_postMessage params
end

def slot_of_slot_text
  items = "スロット"
  ary = 4.times.map {|i| items.split("").sample}
  result = ary.join("")
  if result == "スロット" then
    return result + ":5000chouen:"
  else
    return result
  end
end

def slot_of_slot(channel)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: 'slot of slot',
    text: slot_of_slot_text,
    icon_emoji: ':slot_machine:'
  }
  Slack.chat_postMessage params
end

client.on :message do |data|
  channel = config['channels'].find {|item| item['id'] == data['channel']}
  next unless channel != nil
  channel_name = channel['name']
  next if data.has_key?('reply_to')
  next unless data.has_key?('text')
  p data
  data['text'].each_line do |line|
    if line.start_with?("$", "#", "%") then
      command, *args = get_command(line[1..-1])
      case command
      when "fortune" then
        fortune(channel_name, args)
      when "help" then
        help(channel_name, args)
      when "slot" then
        slot_of_slot(channel_name)
      end
    end
    if line == "スロット" then
      slot(channel_name)
    elsif line.each_char.sort == "スロット".each_char.sort then
      fake_slot(channel_name)
    end
  end
end

client.start
