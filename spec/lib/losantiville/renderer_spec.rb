#

require "spec_helper"

describe Losantiville::Renderer do
  context "with Swagger 2.0 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../../api-with-examples.yaml", __FILE__)
      ))
    end

    it "renders HTML" do
      html = renderer.render
      expect(html).to start_with("<!DOCTYPE html>")
      expect(html).to include("Simple API overview")
    end

    it "renders operations" do
      html = renderer.render
      expect(html).to include("List API versions")
      expect(html).to include("Show API version details")
    end

    it "renders response codes" do
      html = renderer.render
      expect(html).to include("200")
      expect(html).to include("300")
      expect(html).to include("203")
    end
  end

  context "with OpenAPI 3.0 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi3_example.yaml", __FILE__)
      ))
    end

    it "renders HTML" do
      html = renderer.render
      expect(html).to start_with("<!DOCTYPE html>")
      expect(html).to include("Simple API overview")
    end

    it "renders servers" do
      html = renderer.render
      expect(html).to include("Servers")
      expect(html).to include("https://api.example.com/v3")
      expect(html).to include("Production server")
      expect(html).to include("https://staging.example.com/v3")
    end

    it "renders operations with tags" do
      html = renderer.render
      expect(html).to include("List API versions")
      expect(html).to include("Show API version details")
      expect(html).to include("Create a new version")
    end

    it "renders deprecated operations with styling" do
      html = renderer.render
      expect(html).to include('class="summary deprecated"')
    end

    it "renders request body" do
      html = renderer.render
      expect(html).to include("Request Body")
      expect(html).to include("Version to create")
    end

    it "renders security schemes" do
      html = renderer.render
      expect(html).to include("Security Schemes")
      expect(html).to include("bearerAuth")
      expect(html).to include("apiKeyAuth")
    end

    it "resolves $ref to components/schemas" do
      html = renderer.render
      # The VersionList schema references Version which references Link
      # Check that nested refs resolve and produce JSON output
      expect(html).to include('"versions"')
    end

    it "renders response codes" do
      html = renderer.render
      expect(html).to include("200")
      expect(html).to include("201")
      expect(html).to include("404")
    end
  end

  context "with OpenAPI 3.1 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi31_example.yaml", __FILE__)
      ))
    end

    it "renders HTML" do
      html = renderer.render
      expect(html).to start_with("<!DOCTYPE html>")
      expect(html).to include("Simple API overview")
    end

    it "renders webhooks section" do
      html = renderer.render
      expect(html).to include("Webhooks")
      expect(html).to include("Pet adopted notification")
      expect(html).to include("New pet available notification")
      expect(html).to include("webhook")
    end

    it "renders pet operations" do
      html = renderer.render
      expect(html).to include("List all pets")
      expect(html).to include("Create a pet")
      expect(html).to include("Get a pet by ID")
    end

    it "handles nullable type array in schemas" do
      html = renderer.render
      # Pet schema has tag: [string, null] - should render as "string" not error
      expect(html).to include('"tag"')
    end

    it "resolves $ref in schemas correctly" do
      html = renderer.render
      # Pet has id (integer), name (string), tag (nullable string)
      expect(html).to include('"name"')
      expect(html).to include('"id"')
    end
  end

  context "with minimal OpenAPI 3.1 spec missing non-required sections" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi31_minimal.yaml", __FILE__)
      ))
    end

    it "renders HTML without errors" do
      html = renderer.render
      expect(html).to start_with("<!DOCTYPE html>")
      expect(html).to include("Minimal API")
    end

    it "renders operations from spec without tags" do
      html = renderer.render
      expect(html).to include("List items")
      expect(html).to include("Create an item")
      expect(html).to include("Empty endpoint")
    end

    it "renders responses without schema content" do
      html = renderer.render
      expect(html).to include("200")
      expect(html).to include("201")
      expect(html).to include("204")
    end

    it "renders object schema without properties" do
      html = renderer.render
      # The request body has type: object with no properties - should not error
      expect(html).to include("Request Body")
    end
  end

  context "describe_schema" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi31_example.yaml", __FILE__)
      ))
    end

    it "handles allOf composition" do
      schema = { "allOf" => [
        { "$ref" => "#/components/schemas/Pet" },
        { "type" => "object", "properties" => { "extra" => { "type" => "boolean" } } }
      ]}
      result = renderer.describe_schema(nil, schema)
      expect(result).to be_a(Hash)
      expect(result).to have_key("id")
      expect(result).to have_key("name")
      expect(result).to have_key("extra")
    end

    it "handles oneOf composition" do
      schema = { "oneOf" => [
        { "$ref" => "#/components/schemas/Pet" },
        { "$ref" => "#/components/schemas/Version" }
      ]}
      result = renderer.describe_schema(nil, schema)
      # Returns first variant (Pet)
      expect(result).to be_a(Hash)
      expect(result).to have_key("id")
    end

    it "handles anyOf composition" do
      schema = { "anyOf" => [
        { "$ref" => "#/components/schemas/Pet" },
        { "$ref" => "#/components/schemas/Version" }
      ]}
      result = renderer.describe_schema(nil, schema)
      expect(result).to be_a(Hash)
      expect(result).to have_key("id")
    end

    it "handles circular references without stack overflow" do
      # Test cycle detection by manually checking
      schema = { "$ref" => "#/components/schemas/Pet" }
      result = renderer.describe_schema(nil, schema)
      expect(result).to be_a(Hash)
    end

    it "handles nullable type array" do
      schema = { "type" => ["string", "null"] }
      result = renderer.describe_schema(nil, schema)
      expect(result).to eq("string")
    end

    it "handles basic types" do
      expect(renderer.describe_schema(nil, { "type" => "boolean" })).to eq(true)
      expect(renderer.describe_schema(nil, { "type" => "string" })).to eq("string")
      expect(renderer.describe_schema(nil, { "type" => "integer" })).to eq(0)
      expect(renderer.describe_schema(nil, { "type" => "number", "format" => "float" })).to eq(0.0)
    end

    it "handles schema hash without type gracefully" do
      schema = { "description" => "A free-form value" }
      result = renderer.describe_schema(nil, schema)
      expect(result).to eq("")
    end

    it "handles object without properties or additionalProperties gracefully" do
      schema = { "type" => "object" }
      result = renderer.describe_schema(nil, schema)
      expect(result).to be_a(Hash)
      expect(result).to be_empty
    end

    it "handles object with only description and no properties" do
      schema = { "type" => "object", "description" => "An empty object" }
      result = renderer.describe_schema(nil, schema)
      expect(result).to be_a(Hash)
      expect(result).to be_empty
    end
  end
end
