require 'socket'
require 'yaml'

module Ruku

  # Class for Remote to extend that removes most instance methods
  class BlankSlate
    # Keep a few basics and some YAML related methods
    KEEPERS = %w[class object_id != inspect to_yaml to_yaml_style to_yaml_properties] +
      %w[taguri instance_variables instance_variable_get]

    instance_methods.each do |m|
      # Whack every method except those that start with __ or end with ?, figuring
      # that those would be unlikely to be tried to use for Roku commands and
      # possibly useful for other basic stuff.
      ms = m.to_s
      undef_method m unless (ms =~ /^__/ || ms =~ /\?$/ || KEEPERS.include?(ms))
    end
  end

  # Communicates with a Roku box. Known methods that you can call that correspond with buttons
  # on the physical Roku remote include: up, down, left, right, select, home, fwd, back, pause
  #
  # Calling methods with the name of the command you want to send has the same effect as calling
  # send_roku_command with the Symbol (or String) representing your command.
  #
  # Examples:
  #
  #   remote = Remote.new('192.168.1.10') # Use your Roku box IP or hostname
  #   remote.pause                        # Sends play/pause to the Roku box
  #   remote.left.down.select             # Can chain commands if you want to
  #
  # Actually, all prefixes will work for all commands because they are accepted by the Roku box.
  # Unless more commands are added to introduce ambiguities, this means only one character is
  # needed for a command.
  #
  # Examples:
  #
  #   remote.h           # Registers as 'home'
  #
  #   remote.d           # This and the following 3 lines register as 'down'
  #   remote.do
  #   remote.dow
  #   remote.down
  #
  # Despite this working now it is not recommended that you use this in case future added commands
  # create ambiguity and also because it can make code less clear.
  class Remote < BlankSlate
    # The port on which the Roku box listens for commands
    DEFAULT_PORT = 8080

    # Known commands that the Roku box will accept - here mostly for documentation purposes
    KNOWN_COMMANDS = %w[up down left right select home fwd back pause]

    # Scan for Roku boxes on the local network
    def self.scan(stop_on_first=false)
      # TODO: don't just use the typical IP/subnet for a home network; figure it out
      boxes = []
      prefix = '192.168.1.'
      (0..255).each do |host|
        info = Socket.getaddrinfo(prefix + host.to_s, DEFAULT_PORT)
        # Is there a better way to identify a Roku box other than looking for a hostname
        # starting with 'NP-'? There probably is - is the better way also quick?
        boxes << Remote.new(info[0][3]) if info[0][2] =~ /^NP-/i
        break if stop_on_first && !boxes.empty?
      end
      boxes
    end

    attr_accessor :host, :name, :port

    def initialize(host, name=nil, port=DEFAULT_PORT)
      @host, @name, @port = host, name, port
    end

    # Send a "raw" command to the Roku player that is not formatted in the typical style that
    # the box is expecting to receive.
    def send_command(cmd)
      use_tcp_socket {|s| s.write cmd}
      self
    end

    # Send a command to the Roku box in the form "press CMD\n" that is used for known commands.
    def send_roku_command(cmd)
      cmd_string = cmd.to_s # In case it's a symbol, basically

      # For some reason the Roku box can be unresponsive with the full 'select' command. It seems
      # that 'sel' will always work, though, so send that.
      cmd_string = 'sel' if cmd_string == 'select'

      send_command "press #{cmd_string}\n"
    end

    # Consider missing methods to be names of commands to send to the box
    def method_missing(*args)
      # If more than one argument, assume someone is trying to use a method
      # that they don't expect will be turned into a Roku command
      throw 'Roku command takes no arguments' if args.size > 1
      roku_cmd = args[0]
      send_roku_command roku_cmd
    end

    # Overide normal Object select to make it work in the Roku remote sense
    def select
      send_roku_command :select
    end

    # Remotes with the same host are considered equal
    def ==(other)
      host == other.host
    end

    def eql?(other)
      self == other
    end

    def hash
      host.hash
    end

    def <=>(other)
      host <=> other.host
    end

    def to_s
      "<Remote host:#{@host}, name:#{@name || '(none)'}>"
    end

    protected

    # Do something with the TCPSocket in the given block. The socket will be closed afterward.
    def use_tcp_socket
      s = TCPSocket.open(@host, @port)
      yield s
      s.close
    end
  end
end
