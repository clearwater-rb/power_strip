require 'faye/websocket'
require 'redis'
require 'set'
require 'json'

require 'power_strip/channel_list'
require 'power_strip/message'
require 'power_strip/connection'

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
      @connections = {}
    end

    def call env
      if Faye::WebSocket.websocket? env
        socket = Faye::WebSocket.new(env)

        subscriptions = Set.new

        socket.on :message do |event|
          begin
            message = Message.new(JSON.parse(event.data))
            channel_name = message.channel
            channel = channels[channel_name]

            case message.event
            when '@subscribe'
              channel << socket
              subscriptions << channel

              socket.send({
                event: :subscribed,
                channel: channel_name,
              }.to_json)
            when '@unsubscribe'
              subscriptions.delete channel
              channel.delete socket

              socket.send({
                event: :unsubscribed,
                channel: channel_name,
              }.to_json)
            else
              @handlers[channel_name][message.event].each do |callback|
                begin
                  callback[message, @connections[socket]]
                rescue => e
                  warn "[PowerStrip] #{e.inspect}"
                end
              end
            end
          rescue JSON::ParserError
            # Ignore invalid JSON
          end
        end

        socket.on :open do
          @connections[socket] = Connection.new(socket)
        end

        socket.on :close do
          # Remove this connection from all channels it was subscribed to.
          subscriptions.each { |channel| channel.delete socket }
          @connections.delete socket
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
