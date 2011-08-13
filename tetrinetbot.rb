#!/usr/bin/env ruby
# tetrinetbot
# Announce on IRC when the TetriNET server has a single user.
#
# (c) Karl-Martin Skontorp <kms@skontorp.net> ~ http://22pf.org/
# Licensed under the GNU GPL 2.0 or later.

require 'ircbot'
require 'yaml'
require 'pp'
require 'socket'

class Tetrinetbot < IRC::Bot
    def initialize(config)
        @channel = config["channel"]
        super
    end

    def on_001(sender, target, args)
        # connection is established when 001 is received
        # hijack it to autojoin channels
        do_join(@channel)
    end

    def on_privmsg(sender, target, args)

    end

    def on_join(sender, target, args)
        puts "#{sender[0]} JOIN #{target}"
    end
end

config = YAML::load(File.open("tetrinetbot.conf"))

bot = Tetrinetbot.new(config)

threads = []

threads << bot.run
threads << Thread.new {
    alertsent = false
    while true
        sock = TCPSocket.open(config["tetrinethost"], config["tetrinetport"])
        sock.send("listuser\n", 0)
        sleep(0.1) # Jallaballa
        sock.send("\255\n", 0)
        r = sock.readlines
        sock.close

        okLine = r.index("+OK\n")

        if okLine == nil
            print "Bad data from tetrinet server\n"
        else
            users = []
            r[0,okLine].each { |l|
                l.sub(/^\"(.*?)\"/) {
                    users << $1
                }
            }

            pp users

            if users.size == 1
                if alertsent == false
                    bot.do_privmsg(config["channel"], "TetriNET single-user ALERT! [%s]" % users[0])
                    alertsent = true
                end
            else 
                alertsent = false
            end
        end

        sleep(2)
    end
}

threads.each { |t| 
    t.join 
}
