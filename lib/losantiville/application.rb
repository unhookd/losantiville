#

require 'sinatra'
require 'sinatra/reloader'

require 'losantiville/dev'

module Losantiville
  class Application < Sinatra::Application

    class Error < StandardError; end

    post '/' do
      mabb = Markaby::Builder.new

      dashboard_partial_proc = Proc.new { |mab, p|
        specification_io = p["specification"]["tempfile"]
        losantiville_renderer = Losantiville::Renderer.new(specification_io)
        mab.div do
          losantiville_renderer.render
        end
      }

      dashboard_partial_proc.call(mabb, params)

      mabb.to_s
    end

    get '/' do
      mabb = Markaby::Builder.new

      dashboard_partial_proc = Proc.new { |mab|
        mab.div do
          mab.form("id" => "form") do
            mab.input("type" => "file", "id" => "specification", "name" => "specification", "tabindex" => 0)
            mab.input("type" => "submit", "id" => "submit", "tabindex" => 1)
          end
        end
      }

      mabb.html5("lang" => "en") do
        mabb.head do
          mabb.title("losantiville")
          mabb.script("src" => "morphdom-umd-2.5.10.js") {}
          mabb.script("src" => "index.js") {}
        end

        mabb.body do
          mabb.div("id" => "outside-container") do
            mabb.div("id" => "dashboard-container", &dashboard_partial_proc)
          end
        end
      end

      mabb.to_s
    end
  end
end
