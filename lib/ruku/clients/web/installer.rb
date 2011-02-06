module Ruku
  module Clients
    class WebInstaller
      def self.install(port)
        case RUBY_PLATFORM.downcase
        when /darwin/
          osx_install port
        else
          fail('Cannot install for your operating system')
        end
      end

      private

      def self.fail(msg)
        $stderr.puts msg
        exit 1
      end

      def self.osx_install(port)
        # TODO: make finding the executable a little more sophisticated
        executable_path = (ENV['GEM_HOME'] || '/usr') + '/bin/ruku'

        fail('Could not find Ruku executable') if not File.exist?(executable_path)

        plist = <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.aaronroyer.ruku</string>
  <key>KeepAlive</key>
  <true/>
  <key>ProgramArguments</key>
  <array>
    <string>#{executable_path}</string>
    <string>--web</string>
    <string>--port</string>
    <string>#{port}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

        plist_path= '~/Library/LaunchAgents/com.aaronroyer.ruku.plist'
        expanded = File.expand_path plist_path
        begin
          File.open(expanded, 'w') {|f| f.puts plist }
        rescue
          fail "Could not write to #{expanded}"
        end
        $stderr.puts <<-SUCCESS
Ruku installed for launch on startup

To launch right now:
launchctl load -w #{plist_path}
SUCCESS
      end
    end
  end
end
