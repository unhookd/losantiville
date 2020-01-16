# spec/spec_helper.rb

require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'losantiville'

module RSpecMixin
  include Rack::Test::Methods
  def app
    described_class
  end
end

RSpec.configure do |c|
  c.include RSpecMixin
end
