require 'faye/websocket'
require 'redis'
require 'set'
require 'json'

require 'power_strip/channel_list'
require 'power_strip/message'

module PowerStrip
  class App
    attr_reader :redis, :sockets, :channels

    def self.instance(**args)
      @instance ||= new(**args)
    end

    def initialize(redis: Redis.new)
      @redis = redis
      @channels = ChannelList.new(redis: redis)
      @handlers = Hash.new do |channels,channel|
        channels[channel] = Hash.new do |handlers, event|
          handlers[event] = []
        end
      end
    end

    def call env
      if Faye::WebSocket.websocket? env
        socket = Faye::WebSocket.new(env)

        subscriptions = Set.new

        socket.on :message do |event|
          message = Message.new(JSON.parse(event.data))
          channel_name = message.channel
          channel = channels[channel_name]

          case message.event
          when '@subscribe'
            channel << socket
            subscriptions << channel_name

            socket.send({
              event: :subscribed,
              channel: channel_name,
            }.to_json)
          when '@unsubscribe'
            channels[channel_name].delete socket
            if channels[channel_name].empty?
              channels.delete channel_name
            end

            subscriptions.delete channel_name

            socket.send({
              event: :unsubscribed,
              channel: channel_name,
            }.to_json)
          else
            @handlers[channel_name][message.event].each do |callback|
              begin
                callback[message, socket]
              rescue => e
                warn "[PowerStrip] #{e.inspect}"
              end
            end
          end
        end

        socket.on :close do
          subscriptions.each do |channel_name|
            channels[channel_name].delete socket
          end
        end

        socket.rack_response
      else
        bad_request
      end
    end

    def on event, channel:, &block
      @handlers[channel.to_s][event.to_s] << block
    end

    def listen
      redis.dup.subscribe(:power_strip) do |on|
        on.message do |_, message|
          channel = JSON.parse(message)['channel']
          channels[channel].sockets.each do |socket|
            socket.send message
          end
        end
      end
    end

    private

    def bad_request
      [
        400,
        { 'Content-Type' => 'text/plain' },
        ['This endpoint only handles websockets'],
      ]
    end
  end
end
