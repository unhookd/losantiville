#

module Losantiville
  # Normalized specification model that both Swagger 2.0 and OpenAPI 3.x parsers populate.
  # The Renderer reads only from this model.
  class Specification
    attr_accessor :title, :description, :spec_version,
                  :servers, :schemas, :components,
                  :requests_by_tag, :tags, :tags_by_name, :tags_by_groups,
                  :security_schemes, :webhooks_by_tag

    def initialize
      @title = nil
      @description = nil
      @spec_version = nil
      @servers = []
      @schemas = {}
      @components = {}
      @requests_by_tag = {}
      @tags = []
      @tags_by_name = {}
      @tags_by_name["default"] = "default listings"
      @tags_by_groups = nil
      @security_schemes = {}
      @webhooks_by_tag = {}
    end

    # Resolve a $ref string (e.g. "#/definitions/Pet" or "#/components/schemas/Pet")
    # against the stored schemas/components.
    def resolve_ref(ref_string)
      parts = ref_string.split("/")
      # "#/definitions/Name" => ["#", "definitions", "Name"]
      # "#/components/schemas/Name" => ["#", "components", "schemas", "Name"]
      if parts.length == 3 && parts[1] == "definitions"
        @schemas[parts[2]]
      elsif parts.length == 4 && parts[1] == "components"
        component_type = parts[2]
        component_name = parts[3]
        if component_type == "schemas"
          @schemas[component_name]
        elsif @components[component_type]
          @components[component_type][component_name]
        end
      end
    end
  end
end
