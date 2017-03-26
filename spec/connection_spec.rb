require 'power_strip/connection'

module PowerStrip
  RSpec.describe Connection do
    let(:socket) { double('WebSocket') }
    let(:connection) { Connection.new(socket) }

    it 'wraps a socket' do
      expect(socket).to receive(:hello)
      connection.send('hello')
    end

    describe 'metadata' do
      it 'accepts metadata' do
        connection[:foo] = :bar
        expect(connection[:foo]).to eq :bar
      end
    end
  end
end
