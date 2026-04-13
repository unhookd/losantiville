#

module Losantiville
  module SpecificationDetector
    def self.detect_and_parse(raw)
      if raw["swagger"] == "2.0"
        Swagger2.parse(raw)
      elsif raw["openapi"].is_a?(String) && raw["openapi"].match?(/\A3\.(0|1)\.\d+\z/)
        OpenApi3.parse(raw)
      else
        version = raw["swagger"] || raw["openapi"] || "unknown"
        raise "Unsupported specification version: #{version}. Supported: Swagger 2.0, OpenAPI 3.0.x, OpenAPI 3.1.x"
      end
    end
  end
end
