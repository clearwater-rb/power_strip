require 'power_strip/channel'

module PowerStrip
  class ChannelList
    include Enumerable

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

    def each
      @channels.each_value { |channel| yield channel }
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

    def inspect
      longest_name = @channels.each_key.max_by(&:length).length

      <<-EOF
#<#{self.class.name}:0x#{(object_id * 2).to_s(16)}
#{@channels.map { |name, channel| "  #{name.rjust(longest_name)}: #{channel.sockets.length}" }.join("\n") }>
      EOF
    end

    def prune
      @channels.reject! do |name, channel|
        channel.empty?
      end
    end
  end
end
