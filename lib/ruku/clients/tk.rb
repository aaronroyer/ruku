
module Ruku
  class TkClient
    def initialize
      sm = YAMLStorage.new
      sm.load
      @remote = Remote.new(sm.boxes.first.host, 8080)

      launch
    end

    def launch
      require 'tk'
      root = TkRoot.new() { title "Roku Remote"}
      root.bind('KeyPress-Left'){
        @remote.left
      }
      root.bind('KeyPress-Right'){
        @remote.right
      }
      root.bind('KeyPress-Up'){
        @remote.up
      }
      root.bind('KeyPress-Down'){
        @remote.down
      }
      root.bind('KeyPress-Return'){
        @remote.select
      }
      root.bind('KeyPress-space'){
        @remote.pause
      }
      Tk.mainloop
    end
  end
end
