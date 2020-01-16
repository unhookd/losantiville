# config.ru (run with rackup)

project = File.dirname(File.realpath(__FILE__))
lib = File.join(project, "lib")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'losantiville'

use Rack::Static, { :urls => ["/index.js", "/morphdom-umd-2.5.10.js"], :root => 'public' }

run Losantiville::Application
