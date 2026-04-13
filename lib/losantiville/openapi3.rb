#

module Losantiville
  class OpenApi3
    HTTP_METHODS = %w{get put post delete options head patch trace}.freeze

    def self.parse(raw)
      spec = Specification.new
      spec.spec_version = raw["openapi"]

      # Info
      info = raw["info"]
      if info
        spec.title = info["title"]
        spec.description = info["description"]
      end

      # Servers
      servers = raw["servers"]
      if servers
        spec.servers = servers.map do |s|
          { "url" => s["url"], "description" => s["description"], "variables" => s["variables"] }
        end
      end

      # Components
      components = raw["components"] || {}
      spec.schemas = components["schemas"] || {}
      spec.security_schemes = components["securitySchemes"] || {}

      # Store all component types for $ref resolution
      %w{responses parameters requestBodies headers links callbacks}.each do |ctype|
        spec.components[ctype] = components[ctype] if components[ctype]
      end

      # Parse paths
      paths = raw["paths"] || {}
      paths.each do |path, path_item|
        next unless path_item.is_a?(Hash)

        # Collect path-level parameters
        path_level_params = path_item["parameters"]

        HTTP_METHODS.each do |method|
          operation = path_item[method]
          next unless operation.is_a?(Hash)

          # Normalize operation to look like Swagger 2.0 for the renderer
          normalized = normalize_operation(operation, path_level_params, raw, components)

          tags = normalized["tags"]
          if tags && !tags.empty?
            tags.each do |tag|
              spec.requests_by_tag[tag] ||= []
              spec.requests_by_tag[tag] << [method, normalized, path]
            end
          else
            spec.requests_by_tag["default"] ||= []
            spec.requests_by_tag["default"] << [method, normalized, path]
          end
        end
      end

      # Parse tags
      tags = raw["tags"]
      if tags
        spec.tags = tags
        tags.each do |t|
          spec.tags_by_name[t["name"]] = t["description"]
        end
      end

      spec.tags_by_groups = raw["x-tagGroups"]

      # Parse webhooks (OpenAPI 3.1)
      webhooks = raw["webhooks"] || {}
      webhooks.each do |name, path_item|
        next unless path_item.is_a?(Hash)

        # Resolve $ref on the path item itself
        if path_item["$ref"]
          path_item = resolve_component_ref(path_item["$ref"], raw) || path_item
        end

        HTTP_METHODS.each do |method|
          operation = path_item[method]
          next unless operation.is_a?(Hash)

          normalized = normalize_operation(operation, nil, raw, components)

          tag = (normalized["tags"] && normalized["tags"].first) || "webhooks"
          spec.webhooks_by_tag[tag] ||= []
          spec.webhooks_by_tag[tag] << [method, normalized, name]
        end
      end

      spec
    end

    private

    # Normalize an OpenAPI 3.x operation into a structure compatible with the renderer.
    # The renderer expects responses to have "schema" directly on each response code.
    # In OAS3, the schema lives under response -> content -> {media-type} -> schema.
    def self.normalize_operation(operation, path_level_params, raw, components)
      normalized = {
        "summary" => operation["summary"],
        "description" => operation["description"],
        "operationId" => operation["operationId"],
        "tags" => operation["tags"],
        "deprecated" => operation["deprecated"],
        "parameters" => merge_parameters(path_level_params, operation["parameters"]),
        "security" => operation["security"],
        "responses" => {},
        "requestBody" => normalize_request_body(operation["requestBody"], raw, components),
      }

      responses = operation["responses"] || {}
      responses.each do |code, response|
        next unless response.is_a?(Hash)

        # Resolve $ref on response
        if response["$ref"]
          response = resolve_component_ref(response["$ref"], raw) || response
        end

        normalized_response = { "description" => response["description"] }

        # Extract schema from content
        content = response["content"]
        if content.is_a?(Hash)
          # Pick the first content type's schema (prefer application/json)
          media_type = content["application/json"] || content.values.first
          if media_type.is_a?(Hash) && media_type["schema"]
            normalized_response["schema"] = media_type["schema"]
          end

          # Also store the full content map for rich rendering
          normalized_response["content"] = content
        end

        normalized["responses"][code] = normalized_response
      end

      normalized
    end

    def self.normalize_request_body(request_body, raw, components)
      return nil unless request_body.is_a?(Hash)

      # Resolve $ref
      if request_body["$ref"]
        request_body = resolve_component_ref(request_body["$ref"], raw) || request_body
      end

      result = {
        "description" => request_body["description"],
        "required" => request_body["required"],
        "content" => {}
      }

      content = request_body["content"]
      if content.is_a?(Hash)
        content.each do |media_type, media_obj|
          next unless media_obj.is_a?(Hash)
          result["content"][media_type] = {
            "schema" => media_obj["schema"],
            "example" => media_obj["example"],
            "examples" => media_obj["examples"],
          }
        end
      end

      result
    end

    def self.merge_parameters(path_level, operation_level)
      all = []
      all.concat(path_level) if path_level.is_a?(Array)
      all.concat(operation_level) if operation_level.is_a?(Array)
      return nil if all.empty?

      # Operation-level params override path-level by name+in
      seen = {}
      merged = []
      all.reverse.each do |p|
        key = "#{p["name"]}:#{p["in"]}"
        unless seen[key]
          seen[key] = true
          merged.unshift(p)
        end
      end
      merged
    end

    def self.resolve_component_ref(ref_string, raw)
      parts = ref_string.split("/")
      return nil unless parts[0] == "#"

      obj = raw
      parts[1..].each do |part|
        return nil unless obj.is_a?(Hash)
        obj = obj[part]
      end
      obj
    end
  end
end
