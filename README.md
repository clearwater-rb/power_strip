# PowerStrip

PowerStrip is a Ruby library to manage WebSockets easily. It combines the following pieces:

- Rack app you can mount into your Ruby web app to handle incoming WebSocket connections
- Connection manager
- API for handling channels and events

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'power_strip'
```

And then execute:

    $ bundle

## Server-Side Usage

Call `PowerStrip.start` to turn on the PowerStrip and mount `PowerStrip` as an endpoint of your app. Here are a couple of examples to get you started with Rails and Roda:

### Rails

```ruby
# config/initializers/power_strip.rb
PowerStrip.start

# config/routes.rb
mount PowerStrip, at: '/chat' # Example for a chat app
```

### Roda

```ruby
# config.ru
require 'power_strip'

PowerStrip.start

class MyApp < Roda
  r.on('chat') { r.run PowerStrip }
end
```

### Sending updates to clients:

```ruby
PowerStrip[channel_name].send(event_name, key: value)
```

## Client-Side Usage

If your front-end app is written in Ruby (via Opal), you can start with just a few lines of code:

```ruby
require 'opal'
require 'power_strip'

# This URL should point to where you have PowerStrip mounted on the server
client = PowerStrip::Client.new('ws://localhost:9292/chat')

client.on(:connect) { store.dispatch Connected.new }
client.on(:disconnect) { store.dispatch Disconnected.new }

channel = client.subscribe(:chat)
channel.on :message do |message|
  # Tell your app you've received this message. The payload is in message.data.
end
```

### JavaScript

```javascript
// Note: this isn't implemented yet because I'm a Ruby developer
import { Client } from 'power_strip';

const client = new Client('ws://localhost:9292/chat');

client.on('connect', () => dispatch(connected()));
client.on('disconnect', () => dispatch(disconnected()));

const channel = client.subscribe('chat');
channel.on('message', message => {
  dispatch(receivedMessage(message.data));
});
```

## Sending Messages Client->Server

Set up a message handler on the server:

```ruby
require 'power_strip'

# Handle :message events in the "chat" channel.
# @param message [PowerStrip::Message] the message we received
# @param connection [Faye::WebSocket] the client connection this is from
PowerStrip.on :message, channel: 'chat' do |message, connection|
  IncomingMessageWorker.perform_async message
end
```

Notice we don't do work directly on the message. We instead pass it off to a background worker. This is so that we can handle as many incoming messages as possible. To be able to send messages back to that channel, we can simply use the Server->Client message command specified above. Note the `perform` method here:

```ruby
require 'sidekiq'
require 'power_strip'

class IncomingMessageWorker
  include Sidekiq::Worker

  # @param message [PowerStrip::Message]
  def perform(message)
    # Simplest case, we send the message back out to everyone on the same channel
    PowerStrip[message.channel].send :message, message.data
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/clearwater-rb/power_strip. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
