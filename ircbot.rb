# ircbot.rb
#
# (c) Martin Dahl <martin@iz.no>
# Licensed under the MIT license.

require "socket"

module IRC

  class Bot

    def initialize(config)
      @nick, @username, @realname, @host, @server = config["nick"], config["username"],
        config["realname"], config["host"], config["server"]
    end

    def run
      if @host
        @sock = TCPSocket.new(@server["host"], @server["port"], @host)
      else
        @sock = TCPSocket.new(@server["host"], @server["port"])
      end
      thread = Thread.new {
        loop {
          break unless reply = @sock.gets
          cmd, sender, target, args = "", "", "", []
          reply.sub(/^(?::(\S+)\s+)?(\S+)\s+(?::?(\S+))\s*((?:[^:]\S*\s*)*)?(?::(.+))?$/) {
            sender = $1
            cmd = "on_" + $2.downcase
            target = $3
            args = $4.split if $4
            args << $5.chop if $5
          }
          sender = sender ? (sender.include?(?!) ? sender.split(/!|@/) : [sender]) : [@server["host"]]
          send(cmd, sender, target, args) if respond_to?(cmd)
        }
      }
      do_nick(@nick)
      do_user(@username, @host ? @host : "localhost", @server["host"], @realname)
      thread
    end

    def sendq(string)
      @sock.puts string if @sock
    end

    # event handlers

    def on_ping(sender, target, args)
      sendq "PONG :" + target
    end

    def on_433(sender, target, args)
      # somebody stole our nick! omg!
      do_nick(@nick + "_")
    end

    # commands

    def do_user(username, hostname, server, realname)
      sendq "USER #{username} #{hostname} #{server} :#{realname}"
    end

    def do_nick(nick)
      sendq "NICK #{nick}"
    end

    def do_join(channel)
      sendq "JOIN #{channel}"
    end

    def do_privmsg(channel, msg)
      sendq "PRIVMSG #{channel} :#{msg}"
    end

  end

end

