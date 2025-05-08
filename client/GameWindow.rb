require "gosu"

class GameWindow < Gosu::Window
    def initialize
      super(800, 600)
      self.caption = "Danbi Revival"

      #connect_server("124.61.178.91", 9000)
      connect_server("192.168.219.105", 9000)
    end
    
    def update
    end
    
    def draw
    end
  end
  