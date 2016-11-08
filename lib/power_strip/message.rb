require 'grand_central/model'
require 'json'

module PowerStrip
  class Message < GrandCentral::Model
    attributes(:channel, :event, :data)

    def to_json(*args)
      to_h.to_json
    end
  end
end
