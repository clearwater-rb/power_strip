require 'faye/websocket'
require 'grand_central/model'
require 'redis'
require 'set'
require 'json'

require 'power_strip/version'
require 'power_strip/app'

module PowerStrip
  module_function

  def call env
    app.call env
  end

  def app
    @app ||= App.instance
  end

  def start(**args)
    @app = App.instance(**args)
    @thread = Thread.new { app.listen }
  end

  def [] channel
    app.channels[channel]
  end

  def on event_name, channel:, &block
    app.on event_name, channel: channel, &block
  end

  class Channel
    def on message, &block
      PowerStrip.on(message, channel: name, &block)
    end
  end
end

begin
  require 'opal'
  Opal.append_path File.expand_path('../../opal', __FILE__)
rescue LoadError
  require 'sprockets'
  Sprockets.append_path File.expand_path('../js', __FILE__)
end
