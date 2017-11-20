require 'set'

require 'power_strip/message'

module PowerStrip
  class Channel
    attr_reader :name, :sockets

    def initialize(name, channel_list: {}, redis:)
      @name = name
      @channel_list = channel_list
      @redis = redis
      @sockets = Set.new
    end

    def << socket
      @sockets << socket
    end

    def delete socket
      @sockets.delete socket

      # Tell the channel list to GC this channel
      @channel_list.delete @name if empty?
    end

    def empty?
      @sockets.empty?
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

    def close
      PowerStrip.close name
    end
  end
end
