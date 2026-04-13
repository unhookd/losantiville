#

require "spec_helper"

describe Losantiville::Swagger2 do
  let(:raw) do
    Psych.load(File.read(File.expand_path("../../../fixtures/swagger2_example.yaml", __FILE__)))
  end

  let(:spec) { Losantiville::Swagger2.parse(raw) }

  it "parses spec version" do
    expect(spec.spec_version).to eq("2.0")
  end

  it "parses title and description" do
    expect(spec.title).to eq("Simple API overview")
    expect(spec.description).to be_nil
  end

  it "parses paths into requests_by_tag" do
    expect(spec.requests_by_tag).to have_key("default")
    operations = spec.requests_by_tag["default"]
    expect(operations.length).to eq(2)

    methods = operations.map { |m, _, _| m }
    expect(methods).to include("get")
  end

  it "stores schemas from definitions" do
    # The swagger2 example has no definitions, so empty
    expect(spec.schemas).to eq({})
  end

  it "normalizes servers from host/basePath/schemes" do
    spec_with_host = Losantiville::Swagger2.parse({
      "swagger" => "2.0",
      "host" => "api.example.com",
      "basePath" => "/v1",
      "schemes" => ["https", "http"],
      "info" => { "title" => "Test" },
      "paths" => {}
    })
    expect(spec_with_host.servers.length).to eq(2)
    expect(spec_with_host.servers[0]["url"]).to eq("https://api.example.com/v1")
    expect(spec_with_host.servers[1]["url"]).to eq("http://api.example.com/v1")
  end

  it "provides default tag for untagged operations" do
    expect(spec.tags_by_name["default"]).to eq("default listings")
  end
end
