require File.join(File.dirname(__FILE__), *%w[.. .. ruku])
require 'rubygems'
require 'json'
require 'webrick'

include WEBrick

module Ruku
  module Clients
    class Web
      attr_reader :options

      def initialize(opts={})
        @options = OpenStruct.new(opts)
        handle_options

        server_options = {
          :Port => options.port || 3030,
          :DocumentRoot => File.join(File.dirname(__FILE__), 'web_static')
        }
        @server = HTTPServer.new(server_options)

        ['INT', 'TERM'].each do |signal|
          trap(signal) { @server.shutdown }
        end

        @server.mount("/ajax", AjaxServlet)
      end

      def start
        @server.start
      end

      # Parse and handle command line options
      def handle_options
        OptionParser.new do |opts|
          opts.on('-p', '--port PORT') {|p| options.port = p.to_i }
          opts.on('--web') { } # ignore
        end.parse!
      end

      class AjaxServlet < HTTPServlet::AbstractServlet
        def do_GET(req, resp)
          @remote_manager ||= Remotes.new
          @remote_manager.load

          cmd = req.query['command']
          action = req.query['action']
          if cmd
            resp.body = run_command(cmd, req.query['host'])
            raise HTTPStatus::OK
          elsif action
            resp.body = perform_action(action, req.query['data'])
            raise HTTPStatus::OK
          else
            raise HTTPStatus::PreconditionFailed.new("Missing parameter: 'command' or 'action'")
          end
        end

        protected

        # Send a regular remote command to the active remote or the remote with the specified host
        def run_command(cmd, host=nil)
          remote = host.nil? ? @remote_manager.active : @remote_manager.find_by_host(host)
          if remote
            remote.send_roku_command cmd
            "success"
          else
            "error"
          end
        end

        # Perform some remote management action
        def perform_action(action, data)
          if action == 'list'
            # Get a list of known remotes
            @remote_manager.remotes_to_json
          elsif action == 'update'
            @remote_manager.remotes_from_json(data)
            @remote_manager.store
            "success"
          elsif action =~ /^scan/
            # Scan the network for Roku boxes - two different action values are
            # expected: scanForFirst or scanForAll

            # With scanForFirst try to find only one box because that will be the common case
            @remote_manager = Remotes.new(Remote.scan(action == 'scanForFirst'))
            @remote_manager.active.name = 'My Roku Box' if @remote_manager.active
            @remote_manager.store
            @remote_manager.remotes_to_json
          else
            raise HTTPStatus::PreconditionFailed.new("Unknown action: '#{action}'")
          end
        end
      end
    end
  end

  class Remote
    def to_json
      "{\"host\":\"#{@host}\",\"name\":\"#{@name}\",\"port\":#{@port}}"
    end
  end

  class Remotes
    def remotes_to_json
      "{\"remotes\":[#{ @boxes.map{|b| b.to_json}.join(',') }], \"active\":#{@active_index}}"
    end

    def remotes_from_json(json)
      parsed = JSON.parse(json)
      @boxes = []
      parsed['remotes'].each {|r| @boxes << Remote.new(r['host'], r['name'], r['port'] || 8080) }
      @active_index = parsed['active'] || 0
    end
  end
end
