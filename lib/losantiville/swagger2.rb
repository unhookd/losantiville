#

module Losantiville
  class Swagger2
    def self.parse(raw)
      spec = Specification.new
      spec.spec_version = "2.0"

      info = raw["info"]
      if info
        spec.title = info["title"]
        spec.description = info["description"]
      end

      # Normalize servers from host/basePath/schemes
      host = raw["host"]
      base_path = raw["basePath"] || ""
      schemes = raw["schemes"] || ["https"]
      if host
        schemes.each do |scheme|
          spec.servers << { "url" => "#{scheme}://#{host}#{base_path}", "description" => nil }
        end
      end

      spec.schemas = raw["definitions"] || {}

      # Parse paths into requests_by_tag
      paths = raw["paths"]
      if paths
        paths.each do |path, methods|
          methods && methods.each do |method, request|
            next unless request.is_a?(Hash)
            if request["tags"]
              request["tags"].each do |tag|
                spec.requests_by_tag[tag] ||= []
                spec.requests_by_tag[tag] << [method, request, path]
              end
            else
              spec.requests_by_tag["default"] ||= []
              spec.requests_by_tag["default"] << [method, request, path]
            end
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

      # Security definitions
      spec.security_schemes = raw["securityDefinitions"] || {}

      spec
    end
  end
end
