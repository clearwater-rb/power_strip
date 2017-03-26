module PowerStrip
  class Connection
    attr_reader :metadata

    def initialize socket
      @socket = socket
      @metadata = {}
    end

    def [] attribute
      @metadata[attribute]
    end

    def []= attribute, value
      @metadata[attribute] = value
    end

    def method_missing *args, &block
      @socket.public_send *args, &block
    end
  end
end
