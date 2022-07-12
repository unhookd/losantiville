#

Gem::Specification.new do |spec|
  spec.name          = "losantiville"
  spec.version       = "1.0.0"
  spec.authors       = ["Jon Bardin"]
  spec.email         = ["diclophis@gmail.com"]

  spec.summary       = %q{OpenAPI Specification Documentation Generator}
  spec.description   = %q{OpenAPI Specification Documentation Generator}
  spec.homepage      = "https://github.com/unhookd/losantiville"
  spec.license       = "MIT"

  spec.files         = Dir.glob("lib/**/*")
  spec.bindir        = ["bin"]
  spec.executables   = ["losantiville"]
  spec.require_paths = ["lib"]

  spec.add_dependency "markaby", "~> 0.9"
  spec.add_dependency "yajl-ruby", "~> 1.3"
  spec.add_dependency "commonmarker", "~> 0.23"
end
