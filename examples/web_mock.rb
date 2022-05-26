require 'excon'
require 'webmock/rspec'
require 'rspec/autorun'

class Adder
  def initialize(host)
    @conn = Excon.new(host)
  end

  def add(amount, value)
    resp = @conn.request(
      method: 'GET', 
      path: "add/#{amount}/to", 
      query: { 'value' => value }, 
      expects: 200
    )

    resp.body.to_i
  end
end

RSpec.describe Adder do
  describe "#add" do
    it "works" do
      stub_request(:get, %r{.*add/9/to})
        .with(query: { 'value' => '7' })
        .to_return(status: 200, body: '16')

      expect(described_class.new('http://example.com').add(9, 7)).to eq(16)
    end
  end
end