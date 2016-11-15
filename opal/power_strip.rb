require 'bowser/websocket'
require 'promise'

module PowerStrip
  class Client
    attr_reader :url

    def initialize(url)
      @url = url
      @socket = Bowser.websocket(url)
      @socket.autoreconnect!
      @subscriptions = []

      @socket.on(:open) { @subscriptions.each(&:subscribe) }
    end

    def subscribe channel_name
      channel = Channel.new(channel_name, @socket)
      @subscriptions << channel

      if @socket.connected?
        channel.subscribe
      end

      channel
    end

    def on event_name, &block
      @events ||= {
        disconnect: :close,
        connect: :open,
      }

      native_event = @events.fetch event_name do
        raise ArgumentError,
          "event #{event_name} is not a valid event for #{inspect}"
      end

      @socket.on native_event, &block
    end
  end

  Channel = Struct.new(:name, :socket) do
    def on event_name, &block
      socket.on :message do |event|
        message = Message.new(event.data)

        if message.channel == name && message.event == event_name
          block.call message
        end
      end
    end

    def subscribe
      socket.send_message(
        event: :@subscribe,
        channel: name,
      )
    end

    def method_missing event, message
      promise = Promise.new

      if socket.connected?
        socket.send_message({
          channel: name,
          event: event,
          data: message,
        }.select { |k,v| v })
        promise.resolve true
      else
        Bowser.window.delay 1 do
          send(event, message).then { promise.resolve true }
        end
      end

      promise
    rescue => exception
      promise.fail exception
    end
  end

  class Message
    attr_reader :channel, :event, :data

    def initialize(channel: nil, event: nil, data: nil)
      @channel = channel
      @event = event
      @data = data
    end
  end
end
