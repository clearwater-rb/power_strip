require 'power_strip/channel'

module PowerStrip
  class ChannelList
    def initialize(redis:)
      @redis = redis
      @channels = Hash.new do |hash, channel|
        hash[channel.to_s] = Channel.new(
          channel,
          channel_list: self,
          redis: redis,
        )
      end
    end

    def [] name
      @channels[name.to_s]
    end

    def to_a
      @channels.values
    end

    def delete channel_name
      @channels.delete channel_name.to_s
    end

    def has_channel? channel_name
      @channels.key? channel_name.to_s
    end
  end
end
