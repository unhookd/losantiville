#

require "spec_helper"

describe Losantiville::Application do
  it "has a index" do
    get "/"

    expect(last_response).to be_ok
  end
end
