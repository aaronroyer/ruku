module Ruku
  # A collection of Ruku::Remotes. Keeps track of one or multiple Remotes for Roku
  # boxes. Manages things like which box is active for use.
  class Remotes
    include Enumerable

    attr_reader :active_index
    attr_accessor :boxes, :storage

    def initialize(boxes=[], storage=SimpleStorage.new)
      @boxes, @storage = boxes, storage
      boxes.uniq!
      @active_index = 0
    end

    def each(&b)
      boxes.each &b
    end

    def size
      boxes.size
    end

    def empty?
      boxes.empty?
    end

    def [](index)
      boxes[index]
    end

    def []=(index, box)
      boxes[index] = box
    end

    def active
      return boxes[@active_index] if !boxes.empty? && boxes.size > active_index
      nil
    end

    def set_active(box)
      new_index = nil
      boxes.each_with_index {|b,i| new_index = i if b == box} if box.is_a? Remote
      self.active_index = new_index if new_index and new_index < boxes.size
    end

    def find_by_host(host)
      boxes.find {|box| box.host == host}
    end

    def add(box)
      boxes << box
      boxes.sort!.uniq!
    end

    def remove(box)
      host = box.is_a?(Remote) ? box.host : box
      boxes.reject! { |b| b.host == host }
      self.active_index = 0 if @active_index >= boxes.size
      boxes.sort!
    end

    def store
      storage.store(self)
    end

    def load
      loaded = storage.load
      self.boxes, self.active_index = loaded.boxes, loaded.active_index
    end

    private

    def active_index=(index)
      @active_index = index
    end
  end
end
