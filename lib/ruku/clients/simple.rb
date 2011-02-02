require File.join(File.dirname(__FILE__), *%w[.. .. ruku])
require 'optparse'
require 'ostruct'

module Ruku
  module Clients
    # Provides a little wrapper around a Ruku::Remotes for ease of making
    # a command line client or messing around in an IRB session
    class Simple
      OPERATION_NAMES = %w[scan list add remove name activate help]

      attr_accessor :remotes

      def initialize(rs=Ruku::Remotes.new)
        @remotes = rs
      end

      # Run from the command line. This parses options as well as the command
      # or Ruku operation to run.
      def run_from_command_line
        handle_exceptions do
          remotes.load
          handle_options
          execute_command_from_command_line
        end
      end

      # Checks the command line arguments for a command (options should have already
      # been parsed and removed) and then sends a Roku command or runs an operation
      # on the RemoteManager.
      def execute_command_from_command_line
        cmd = ARGV[0]
        if not cmd
          puts CMD_LINE_HELP
        elsif OPERATION_NAMES.include?(cmd) && !options.force_command
          begin
            self.send(*ARGV)
          rescue ArgumentError => ex
            $stderr.puts "Wrong number of arguments (#{ARGV.size-1}) for operation: #{cmd}"
          end
        else
          send_roku_command cmd
        end
      end

      # Client options generally parsed from the command line
      def options
        @options ||= OpenStruct.new
      end

      # Parse and handle command line options
      def handle_options
        opts = OptionParser.new do |opts|
          opts.on('-c', '--force-roku-command') { options.force_command = true }
        end.parse!
      end

      # Send a command to the active box
      def send_roku_command(cmd)
        if remotes.empty?
          raise UsageError, "No known Roku boxes\n" +
            "Try 'ruku scan' to find them, or 'ruku add HOST NAME' to add one manually"
        else
          remotes.active.send_roku_command cmd
        end
      end

      # Ruku command line "operations" follow

      # Scan for boxes
      def scan
        remotes.boxes = Ruku::Remote.scan
        remotes.each_with_index do |box, i|
          box.name = "My Roku Box#{i == 1 ? i+1 : ''}"
        end
        if remotes.empty?
          puts 'Did not find any Roku boxes'
        else
          puts 'Roku boxes found:'
          remotes.each_with_index do |box, i|
            print "#{i+1}. #{box.name || '(no name)'} at #{box.host}"
            print "#{' <-- active' if i == remotes.active_index && remotes.size > 1}\n"
          end
          store
        end
      end

      # List the boxes we know about
      def list
        if remotes.empty?
          puts "No Roku boxes known\n" +
            "Use the scan or add operations to find or add boxes"
        else
          puts 'Roku boxes:'
          remotes.each_with_index do |box, i|
            print "#{i+1}. #{box.name || '(no name)'} at #{box.host}"
            print "#{' <-- active' if i == remotes.active_index}\n"
          end
        end
      end

      # Add a box
      def add(host=nil, name='My Roku Box')
        raise UsageError, 'Must specify host of box to add' if not host

        if existing = remotes.find_by_host(host)
          existing.name = name
        else
          remotes.add(Ruku::Remote.new(host, name))
        end
        store
        puts "Added remote with host: #{host} and name: #{name}"
      end

      # Remove a box with the given number (from the list operation) or hostname
      def remove(number=nil)
        raise UsageError, 'Must specify number from boxes list or hostname/IP address' if not number

        prev_count = remotes.size
        msg = 'Box '
        if number.is_a?(Integer) || number =~ /^\d+$/
          index = number.to_i - 1
          remotes.boxes.delete_at(index)
          msg << (index + 1).to_s
        else
          remotes.remove(number)
          msg << "with IP/host #{number}"
        end
        msg << ' removed'

        if prev_count == remotes.size + 1
          remotes.store
          puts msg
        else
          puts "Could not remove box: #{number}"
        end
      end

      def name(number=nil, name=nil)
        raise UsageError, 'Must specify number from remotes list or IP/hostname' if not number
        raise UsageError, 'Must specify name for box' if not name

        msg = 'Box '
        if number.is_a?(Integer) || number =~ /^\d+$/
          self[number.to_i].name = name
          msg << (number).to_s
        else
          remotes.find_by_host(number).name = name
          msg << "with IP/host #{number}"
        end
        msg << " renamed to #{name}"
        store
        puts msg
      end

      def activate(number=nil)
        raise UsageError, 'Must specify number from remotes list or IP/hostname' if not number

        msg = 'Box '
        box = if number.is_a?(Integer) || number =~ /^\d+$/
          msg << (number).to_s
          self[number.to_i]
        else
          msg << "with IP/host #{number}"
          remotes.find_by_host(number)
        end

        if box
          remotes.set_active(box)
          store
          puts msg + ' activated for use'
        else
          puts 'Unknown box specified'
        end
      end

      def help
        puts CMD_LINE_HELP
      end

      # Methods not directly available from the command line

      # Get remotes using 1-based index for the command line
      def [](num)
        remotes[num-1]
      end

      # Assign and store remotes using 1-based index for the command line
      def []=(num, box)
        remotes[num-1] = box
        store
      end

      def store
        remotes.store
      end

      private

      def handle_exceptions
        begin
          yield
        rescue SystemExit
          exit
        rescue UsageError => ex
          $stderr.puts ex.message
          exit 1
        rescue OptionParser::InvalidOption => ex
          $stderr.puts ex.message
          exit 1
        rescue Exception => ex
          display_error_message ex
          exit 1
        end
      end

      def display_error_message(ex)
        msg = <<MSG
The Ruku application has aborted! If this is unexpected, you may want to open
an issue at github.com/aaronroyer/ruku to get a possible bug fixed. If you do,
please include the debug information below.
MSG
        $stderr.puts msg
        $stderr.puts ex.message
        $stderr.puts ex.backtrace
      end
    end

    class UsageError < Exception
    end
  end
end
