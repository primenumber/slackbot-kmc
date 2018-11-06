require 'slack'
require 'yaml'
require 'openssl'
require_relative 'othello'

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
  if args.empty? then
    params = {
      token: SLACK_TOKEN,
      channel: channel,
      username: 'help',
      text: "`$ othello`\n`$ help`\n`$ fortune`\n`$ slot`\n`$ isprime`\n`スロット`",
      icon_emoji: ':sos:'
    }
    Slack.chat_postMessage params
  else
    case args[0]
    when "othello" then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'help',
        text: "`$ othello play HAND` (ex. `$ othello play d3`, `$ othello play ps`)\n`$ othello newgame TURN` (ex. `$othello newgame black`)\n`$ othello show`",
        icon_emoji: ':sos:'
      }
      Slack.chat_postMessage params
    when "help" then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'help',
        text: "`$ help [COMMAND]` (ex. `$ help fortune`)",
        icon_emoji: ':sos:'
      }
      Slack.chat_postMessage params
    when "fortune" then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'help',
        text: "`$ fortune`",
        icon_emoji: ':sos:'
      }
      Slack.chat_postMessage params
    when "slot" then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'help',
        text: "`$ slot`",
        icon_emoji: ':sos:'
      }
      Slack.chat_postMessage params
    when "isprime" then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'help',
        text: "`$ isprime NUMBER` (ex. `$ isprime 57`)",
        icon_emoji: ':sos:'
      }
      Slack.chat_postMessage params
    end
  end
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

def is_prime(channel, args)
  begin
    n = OpenSSL::BN.new(args[0])
    if n.prime? then
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'prime judge',
        text: "#{args[0]} is a prime number.",
        icon_emoji: ':male-judge:'
      }
      Slack.chat_postMessage params
    else
      params = {
        token: SLACK_TOKEN,
        channel: channel,
        username: 'prime judge',
        text: "#{args[0]} is not a prime number.",
        icon_emoji: ':male-judge:'
      }
      Slack.chat_postMessage params
    end
  rescue
    params = {
      token: SLACK_TOKEN,
      channel: channel,
      username: 'prime judge',
      text: "#{args[0]} is not a number.",
      icon_emoji: ':male-judge:'
    }
    Slack.chat_postMessage params
  end
end

def is_base81(str)
  return false if str.length != 16
  str.each_byte { |b|
    return false if b < 33
    b -= 33
    a3 = b / 32
    return false if a3 > 3
    b %= 32
    return false if b >= 27
  }
  return true
end

$oth = Othello.new

def othello_post(channel, text)
  params = {
    token: SLACK_TOKEN,
    channel: channel,
    username: 'othello bot',
    text: text,
    icon_emoji: ':riba-si:'
  }
  Slack.chat_postMessage params
end

def othello_think(channel)
  result = $oth.think
  othello_post(channel, "#{result.join(' ')}\n```\n#{$oth}\n```")
end

def othello_invalid_move(channel, hand, e)
  othello_post(channel, "#{e.message}: #{hand[0...2]}")
end

def othello_board_post(channel)
  othello_post(channel, "```\n#{$oth}\n```\n#{$oth.to_base81}")
end

def othello(channel, args)
  p args
  case args[0]
  when "play"
    begin
      if args[1] == "ps" then
        raise "invalid pass" if $oth.movable?
        $oth.pass
      else
        x, y = $oth.hand_to_xy(args[1])
        $oth.move(x, y)
      end
      othello_board_post(channel)
      othello_think(channel)
    rescue => e
      othello_invalid_move(channel, args[1], e)
      othello_board_post(channel)
    end
  when "newgame"
    if args[1] == "black" then
      $oth = Othello.new
      othello_board_post(channel)
    elsif args[1] == "white" then
      $oth = Othello.new
      othello_board_post(channel)
      othello_think(channel)
    else
      othello_post(channel, "invalid color: #{args[1]}")
    end
  when "show"
    othello_board_post(channel)
  end
end


client.on :message do |data|
  channel = config['channels'].find {|item| item['id'] == data['channel']}
  next unless channel != nil
  channel_name = channel['name']
  next if data.has_key?('reply_to')
  next unless data.has_key?('text')
  if data.has_key?('subtype') then
    next if data['subtype'] == 'bot_message'
  end
  p data
  data['text'].each_line do |line|
    if line.start_with?("$", "#", "%") then
      command, *args = get_command(line[1..-1])
      case command
      when "fortune" then
        fortune(channel_name, args)
      when "help" then
        help(channel_name, args)
      when "othello" then
        othello(channel_name, args)
      when "slot" then
        slot_of_slot(channel_name)
      when "isprime" then
        is_prime(channel_name, args)
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
