require 'bowser/websocket'
require 'promise'

module PowerStrip
  class Client
    attr_reader :url

    def initialize(url)
      @url = url
      @socket = Bowser.websocket(url)
      @socket.autoreconnect!
      @subscriptions = {}

      @socket.on :open do
        @subscriptions.each { |name, channel| channel.subscribe }
      end
      @socket.on :message do |event|
        message = Message.new(event.data)
        channel = @subscriptions[message.channel]

        if channel
          channel.receive_message message
        end
      end
    end

    def subscribe channel_name
      channel = Channel.new(channel_name, self)

      @subscriptions[channel_name] = channel
      channel.subscribe

      channel
    end

    def unsubscribe channel_name
      channel = @subscriptions.delete(channel_name)
      return if channel.nil?

      channel.unsubscribe if @socket.connected?

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

    def send_message channel=nil, event=nil, data=nil
      promise = Promise.new

      if @socket.connected?
        @socket.send_message({ channel: channel, event: event, data: data }
          .select { |k,v| v })
        promise.resolve true
      else
        Bowser.window.delay 1 do
          send_message(channel, event, data)
            .then { promise.resolve true }
        end
      end

      promise
    rescue => exception
      promise.fail exception
    end
  end

  class Channel
    attr_reader :name, :client

    def initialize name, client
      @name = name
      @client = client
      @handlers = Hash.new { |h, k| h[k] = [] }
    end

    def on event_name, handler=nil, &block
      unless handler || block
        raise ArgumentError, 'PowerStrip::Channel#on requires an event handler'
      end

      @handlers[event_name] << (handler || block)
    end

    def receive_message message
      @handlers[message.event].each do |handler|
        handler.call message
      end
    end

    def subscribe
      send :@subscribe, nil
    end

    def unsubscribe
      send :@unsubscribe, nil
    end

    def send event, message=nil
      client.send_message(name, event, message)
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
