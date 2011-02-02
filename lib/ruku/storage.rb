module Ruku
  class Storage
    FILE_NAME = '.ruku-boxes'
    attr_accessor :storage_path

    def initialize(path=nil)
      @storage_path = path
      if not @storage_path
        home = ENV['HOME']
        home = ENV['USERPROFILE'] if not home
        if !home && (ENV['HOMEDRIVE'] && ENV['HOMEPATH'])
          home = File.join(ENV['HOMEDRIVE'], ENV['HOMEPATH'])
        end
        home = File.expand_path('~') if not home
        home = 'C:/' if !home && RUBY_PLATFORM =~ /mswin|mingw/

        raise "Could not find user HOME directory" if not home

        @storage_path = File.join(home, FILE_NAME)
      end
    end
  end

  # Stores Roku box information on disk in a plain text file, one box per
  # line, in the format:
  #
  # HOSTNAME:BOX_NAME
  #
  # HOSTNAME is the hostname or IP address of a Roku box. This is the only
  # required portion of the box configuration line. You may also include an
  # optional, more readable box name.
  #
  # Examples of valid box config lines include:
  #
  # 192.168.1.7
  # 192.168.1.8:Living Room
  # NP-20F8A0003472:Bedroom
  class SimpleStorage < Storage

    def store(remotes)
      File.open(@storage_path, 'w') do |f|
        remotes.each {|r| f.puts "#{r.host}#{r.name ? ':'+r.name : ''}" }
      end
    end

    def load
      if File.exist? @storage_path
        remotes = Remotes.new
        IO.read(@storage_path).split("\n").each do |line|
          host, name = line.split(':')
          remotes.boxes << Remote.new(host, name)
        end
        remotes
      else
        Remotes.new
      end
    end
  end

  # Stores Roku box information on disk in YAML
  class YAMLStorage < Storage

    def store(manager)
      File.open(@storage_path, 'w') do |out|
        YAML.dump(manager, out)
      end
    end

    def load
      if File.exist? @storage_path
        YAML.load_file(@storage_path)
      else
        Remotes.new
      end
    end
  end
end
