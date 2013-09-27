require 'rubygems'
require 'bud'
require 'chat_protocol'

class ChatClient
  include Bud
  include ChatProtocol

  def initialize(nick, server, opts={})
    @nick = nick
    @server = server
    super opts
  end

  bootstrap do
    connect <~ [[@server, ip_port, @nick]]
  end

  bloom do
    mcast <~ stdio do |s|
      [@server, [ip_port, @nick, Time.new.strftime("%I:%M.%S"), s.line]]
    end

    stdio <~ mcast { |m| [pretty_print(m.val)] }
  end

  # format chat messages with timestamp on the right of the screen
  def pretty_print(val)
    str = val[1].to_s + ": " + (val[3].to_s || '')
    pad = "(" + val[2].to_s + ")"
    return str + " "*[66 - str.length,2].max + pad
  end
end

if ARGV.length == 2
  server = ARGV[1]
else
  server = ChatProtocol::DEFAULT_ADDR
end

puts "Server address: #{server}"
program = ChatClient.new(ARGV[0], server, :read_stdin => true)
program.run_fg