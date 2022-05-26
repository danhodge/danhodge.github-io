---
layout: post
title:  "Testing HTTP Requests Without Changing Your Application"
date:   2022-05-25 21:04:45 -0400
categories: tools
tags: ruby excon webmock testing
---

A question that comes up frequently is how much, if at all, should you change your application code in order to make it easier to test.
In general, when you follow a lot of the common best practices for software development, you wind up with code that is easier to test, even if that wasn't the main reason for using those practices.
Things that are done in the name of making code easier to understand and maintain, like breaking code into small, self-contained classes or functions, using pure functions, and isolating side-effects often have the added benefit of making it easier to test.

I've run into this question a lot when trying to test code that makes HTTP requests to external services.
In most testing scenarios, these requests need to be stubbed, mocked, or faked so the test doesn't actually try to send a request to the actual service.
My HTTP library of choice is [`excon`](https://github.com/excon/excon), which, in addition to providing an intuitive API for making HTTP requests, also makes it easy to [stub](https://github.com/excon/excon#stubs) out requests with fake responses.
One pattern I've used extensively is passing an optional boolean `mock` parameter into the class or method that is using `excon` to make requests to external services to make it easy to switch on the mocked requests behavior in unit tests.

```ruby
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
```

This works, but it requires changing code solely for the purpose of making it easier to test.
There is never any reason for `mock` to be `true` except in a unit test.
I'm not neccesarily opposed to changes like this, but I'd rather avoid them unless they are absolutely necessary.

Fortunately, there's a better way.
The `excon` library exposes a Hash of default values that can be used to, among other things, set `mock` to `true`.
Any `excon` request property that is not set explicitly in the code will fall back to the default value in this Hash when the request is performed.
Using this approach, the same testing strategy outlined above can be used without having to pass the `mock` parameter into `Adder#initialize`.

```ruby
require 'excon'
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
  before do
    Excon.defaults[:mock] = true
  end

  after do
    Excon.defaults.delete(:mock)
  end

  describe "#add" do
    it "works" do
      Excon.stub(
        { method: 'GET', path: '/add/9/to', query: { 'value' => 7 } }, 
        { status: 200, body: '16' }
      )

      expect(described_class.new('http://example.com').add(9, 7)).to eq(16)
    end
  end
end
```

Finally, there's [`webmock`](https://github.com/bblimke/webmock), which takes a different approach.
Instead of requiring test-specific logic in your application code or global configuration defaults, it intercepts HTTP requests before they are sent over the network and provides a fluent DSL for stubbing them out in tests.
Because `webmock` works by intercepting HTTP requests, it can only be used with supported HTTP libraries, but it supports all of the most popular Ruby HTTP libraries, so unless you're doing something very unusual, it should just work.

Traditionally, `webmock` has not been the tool I've reached for when stubbing out HTTP requests in tests.
While it does require adding an additional (test-only) dependency to your project, I think there are a lot of advantages to using `webmock` over `excon`'s built-in stubbing.
The `webmock` DSL is very intuitive and full-featured and it only touches test code so there's no need to contort your application logic or configuration to support mocking.
Finally, if you use `webmock` and then need to switch the HTTP library in your project for some reason, as long as you're switching to another library that is supported by `webmock`, you shouldn't need to change your tests.


```ruby
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
```