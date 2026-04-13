#

require "spec_helper"

describe Losantiville::OpenApi3 do
  context "with OpenAPI 3.0 spec" do
    let(:raw) do
      Psych.load(File.read(File.expand_path("../../../fixtures/openapi3_example.yaml", __FILE__)))
    end

    let(:spec) { Losantiville::OpenApi3.parse(raw) }

    it "parses spec version" do
      expect(spec.spec_version).to eq("3.0.3")
    end

    it "parses title and description" do
      expect(spec.title).to eq("Simple API overview")
      expect(spec.description).to include("OpenAPI 3.0")
    end

    it "parses servers" do
      expect(spec.servers.length).to eq(2)
      expect(spec.servers[0]["url"]).to eq("https://api.example.com/v3")
      expect(spec.servers[0]["description"]).to eq("Production server")
      expect(spec.servers[1]["url"]).to eq("https://staging.example.com/v3")
    end

    it "parses schemas from components" do
      expect(spec.schemas).to have_key("Version")
      expect(spec.schemas).to have_key("VersionList")
      expect(spec.schemas).to have_key("Link")
      expect(spec.schemas).to have_key("VersionInput")
    end

    it "parses tags" do
      expect(spec.tags_by_name).to have_key("versions")
      expect(spec.tags_by_name["versions"]).to eq("API version management")
    end

    it "parses paths into requests_by_tag" do
      expect(spec.requests_by_tag).to have_key("versions")
      operations = spec.requests_by_tag["versions"]
      expect(operations.length).to eq(3)
    end

    it "normalizes response schema from content" do
      versions_ops = spec.requests_by_tag["versions"]
      list_op = versions_ops.find { |m, r, p| r["operationId"] == "listVersionsv3" }
      expect(list_op).not_to be_nil

      _, request, _ = list_op
      response_200 = request["responses"]["200"]
      expect(response_200["schema"]).to have_key("$ref")
      expect(response_200["schema"]["$ref"]).to eq("#/components/schemas/VersionList")
    end

    it "preserves deprecated flag" do
      versions_ops = spec.requests_by_tag["versions"]
      detail_op = versions_ops.find { |m, r, p| r["operationId"] == "getVersionDetailsv3" }
      _, request, _ = detail_op
      expect(request["deprecated"]).to be true
    end

    it "normalizes requestBody" do
      versions_ops = spec.requests_by_tag["versions"]
      create_op = versions_ops.find { |m, r, p| r["operationId"] == "createVersionv3" }
      _, request, _ = create_op
      expect(request["requestBody"]).not_to be_nil
      expect(request["requestBody"]["required"]).to be true
      expect(request["requestBody"]["content"]).to have_key("application/json")
      expect(request["requestBody"]["content"]["application/json"]["schema"]["$ref"]).to eq("#/components/schemas/VersionInput")
    end

    it "parses security schemes" do
      expect(spec.security_schemes).to have_key("bearerAuth")
      expect(spec.security_schemes).to have_key("apiKeyAuth")
      expect(spec.security_schemes["bearerAuth"]["type"]).to eq("http")
      expect(spec.security_schemes["apiKeyAuth"]["type"]).to eq("apiKey")
    end

    it "has no webhooks for 3.0 spec" do
      expect(spec.webhooks_by_tag).to be_empty
    end
  end

  context "with OpenAPI 3.1 spec" do
    let(:raw) do
      Psych.load(File.read(File.expand_path("../../../fixtures/openapi31_example.yaml", __FILE__)))
    end

    let(:spec) { Losantiville::OpenApi3.parse(raw) }

    it "parses spec version" do
      expect(spec.spec_version).to eq("3.1.0")
    end

    it "parses webhooks" do
      expect(spec.webhooks_by_tag).not_to be_empty
      expect(spec.webhooks_by_tag).to have_key("pets")

      webhook_ops = spec.webhooks_by_tag["pets"]
      expect(webhook_ops.length).to eq(2)

      names = webhook_ops.map { |_, _, name| name }
      expect(names).to include("petAdopted")
      expect(names).to include("newPetAvailable")
    end

    it "parses paths alongside webhooks" do
      expect(spec.requests_by_tag).to have_key("versions")
      expect(spec.requests_by_tag).to have_key("pets")

      pet_ops = spec.requests_by_tag["pets"]
      expect(pet_ops.length).to eq(3)
    end

    it "handles nullable type array (3.1 style)" do
      pet_schema = spec.schemas["Pet"]
      tag_prop = pet_schema["properties"]["tag"]
      expect(tag_prop["type"]).to eq(["string", "null"])
    end

    it "stores allOf composition schemas" do
      expect(spec.schemas).to have_key("ComposedModel")
      expect(spec.schemas["ComposedModel"]["allOf"]).to be_an(Array)
    end

    it "stores oneOf composition schemas" do
      expect(spec.schemas).to have_key("OneOfModel")
      expect(spec.schemas["OneOfModel"]["oneOf"]).to be_an(Array)
    end

    it "stores anyOf composition schemas" do
      expect(spec.schemas).to have_key("AnyOfModel")
      expect(spec.schemas["AnyOfModel"]["anyOf"]).to be_an(Array)
    end
  end
end
