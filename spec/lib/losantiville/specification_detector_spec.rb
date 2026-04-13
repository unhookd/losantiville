#

require "spec_helper"

describe Losantiville::SpecificationDetector do
  it "detects Swagger 2.0" do
    raw = { "swagger" => "2.0", "info" => { "title" => "Test" }, "paths" => {} }
    spec = Losantiville::SpecificationDetector.detect_and_parse(raw)
    expect(spec).to be_a(Losantiville::Specification)
    expect(spec.spec_version).to eq("2.0")
  end

  it "detects OpenAPI 3.0.x" do
    raw = { "openapi" => "3.0.3", "info" => { "title" => "Test" }, "paths" => {} }
    spec = Losantiville::SpecificationDetector.detect_and_parse(raw)
    expect(spec).to be_a(Losantiville::Specification)
    expect(spec.spec_version).to eq("3.0.3")
  end

  it "detects OpenAPI 3.1.x" do
    raw = { "openapi" => "3.1.0", "info" => { "title" => "Test" }, "paths" => {} }
    spec = Losantiville::SpecificationDetector.detect_and_parse(raw)
    expect(spec).to be_a(Losantiville::Specification)
    expect(spec.spec_version).to eq("3.1.0")
  end

  it "raises on unsupported version" do
    raw = { "openapi" => "4.0.0", "info" => { "title" => "Test" } }
    expect {
      Losantiville::SpecificationDetector.detect_and_parse(raw)
    }.to raise_error(RuntimeError, /Unsupported specification version/)
  end

  it "raises on missing version" do
    raw = { "info" => { "title" => "Test" } }
    expect {
      Losantiville::SpecificationDetector.detect_and_parse(raw)
    }.to raise_error(RuntimeError, /Unsupported specification version/)
  end
end
