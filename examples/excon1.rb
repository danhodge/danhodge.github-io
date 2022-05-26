require 'excon'
require 'rspec/autorun'

class Adder
  def initialize(host, mock: false)
    @conn = Excon.new(host, mock: mock)
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
      Excon.stub(
        { method: 'GET', path: '/add/9/to', query: { 'value' => 7 } }, 
        { status: 200, body: '16' }
      )

      expect(described_class.new('http://example.com', mock: true).add(9, 7)).to eq(16)
    end
  end
end