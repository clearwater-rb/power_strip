require 'set'

require 'power_strip/message'

module PowerStrip
  class Channel
    attr_reader :name, :sockets

    def initialize(name, redis:)
      @name = name
      @redis = redis
      @sockets = Set.new
    end

    def << socket
      @sockets << socket
    end

    def delete socket
      @sockets.delete socket
    end

    def send event, message
      message = Message.new(
        channel: name,
        event: event,
        data: message
      )
      @redis.publish :power_strip, message.to_json
      self
    end
  end
end
