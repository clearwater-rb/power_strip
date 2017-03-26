require 'power_strip/channel_list'
require 'power_strip/channel'

module PowerStrip
  RSpec.describe Channel do
    it 'deletes itself when it is empty' do
      channel_list = ChannelList.new(redis: double)
      channel = channel_list[:my_channel]
      client1 = double
      client2 = double

      channel << client1 << client2
      channel.delete client1

      expect(channel_list).to have_channel :my_channel

      channel.delete client2

      expect(channel_list).not_to have_channel :my_channel
    end
  end
end
