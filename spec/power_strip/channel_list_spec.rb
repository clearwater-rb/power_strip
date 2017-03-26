require 'power_strip/channel_list'

module PowerStrip
  RSpec.describe ChannelList do
    it 'adds a channel if it does not exist' do
      list = ChannelList.new(redis: double)

      expect(list).not_to have_channel :test

      list[:test]

      expect(list).to have_channel :test
    end
  end
end
