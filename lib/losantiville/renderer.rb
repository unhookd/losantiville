#!/usr/bin/env ruby

module Losantiville
  class MyMarkdownRenderer < CommonMarker::HtmlRenderer
    #TODO: include normalizers

    def initialize
      super
    end

    def header(node)
      block do
        case node.header_level
          when 2
            out("<h", node.header_level, " id=\"section/#{node.to_plaintext.gsub(" ", "-").strip}\">",
                     :children, "</h", node.header_level, ">")
        else
          super
        end
      end
    end
  end

  class Renderer
    def initialize(specification_io)
      @specification = Psych.load(specification_io)
      @specification_bits = %w{
        swagger
        host
        basePath
        schemes
        consumes
        produces
        info
        definitions
        paths
        tags
        x-tagGroups
        securityDefinitions
      }
      @definitions = {}
      @response_samples_by_path_and_code = {}
      @sections = {}
      @requests_by_tag = {}
      @tags = []
      @tags_by_group = []
      @tags_by_name = {}
      @tags_by_name["default"] = "default listings"

      parse_specification!
    end

    def render
      if @description
        description = CommonMarker.render_doc(@description, :DEFAULT)

        description.walk do |node|
          case node.type
            when :header
              case node.header_level
                when 2
                  section = node.to_plaintext
                  @sections[section] = URI::Generic.build(:fragment => "section/#{section.gsub(" ", "-").strip}")

              end
          end
        end
      else
        description = nil
      end

      section_nav = %q{<ul class="sections">}
      @sections.each { |section, href|
        section_nav += %Q{<li><h3><a href="#{href}">#{section}</a></h3></li>}
      }
      section_nav += %q{</ul>}

      raw_definition_related_requests = ""
      @requests_by_tag.each { |rk_tag, related_requests|
        raw_definition_related_requests += %Q{
          <h3 class="tag" id="tag-#{rk_tag.gsub(" ", "-")}">
            <a href="#tag-#{rk_tag.gsub(" ", "-")}">#{rk_tag}</a>
          </h3>
          <p>#{@tags_by_name[rk_tag] ? CommonMarker.render_html(@tags_by_name[rk_tag]) : 'no-tag'}</p>
        }

        raw_definition_related_requests += %q{<div><ul>}
        related_requests.each { |related_method, related_request, related_path|
          raw_definition_related_requests += %Q{
            <li>
              <h5 class="summary" id="summary-#{rk_tag}-#{related_method}-#{related_path}">
                <a href="#summary-#{rk_tag}-#{related_method}-#{related_path}">#{related_request["summary"]}</a>
              </h5>
              #{related_request["description"] ? CommonMarker.render_html(related_request["description"], :DEFAULT) : ""}
              <p>
                <tt>#{related_method.upcase}</tt> <tt>#{related_path}</tt>
              </p>
          }

          all_requests_paths_bits = %q{}
          all_requests_paths_tabs = %q{}
          all_requests_paths_bits += %q{<div class="tabs">}

          related_request["responses"].each { |code, response|
            all_requests_paths_tabs += %Q{<a class="response-code" href="##{related_method}-#{related_path}-#{code}">#{code}</a>}

            all_requests_paths_bits += %Q{<div id="#{related_method}-#{related_path}-#{code}"><pre>}
            if schema = response["schema"]
              all_requests_paths_bits += JSON.pretty_generate(describe_schema("schema", schema))
            end
            all_requests_paths_bits += %Q{</pre></div>}
          }

          all_requests_paths_bits += %q{</div>}
          all_requests_paths_bits += %q{}

          raw_definition_related_requests += all_requests_paths_tabs + all_requests_paths_bits
          raw_definition_related_requests += %q{</li>}
        }

        raw_definition_related_requests += %q{</ul></div>}
      }

      raw_sections = ""

      @tags_by_groups && @tags_by_groups.each { |group_item|
        group = group_item["name"]
        tags = group_item["tags"]

        raw_sections += %Q{<h4 id="group-#{group.gsub(" ", "-")}"><a href="#group-#{group.gsub(" ", "-")}">#{group}</a></h4>}

        tags.each { |api_tag|
          raw_request_summaries = []

          if requests_by_tag = @requests_by_tag[api_tag]
            raw_sections += %Q{<h5><a href="#tag-#{api_tag.gsub(" ", "-")}">#{api_tag}</a></h5>}

            requests_by_tag.each { |method, request, path|
              raw_request_summaries << "<li>" +
              %Q{<a class="#{method}" href="#summary-#{request["tags"].first}-#{method}-#{path}">#{request["summary"]}</a>} +
              %q{</li>}
            }
          end

          raw_sections += %q{<ul class="groups">} + raw_request_summaries.join + "</ul>"
        }
      }

      raw_body = %Q{
        <style>
          html { font-family: sans-serif; font-size: smaller; }
          html, body, #outside-container, #dashboard-container, #wrapper { height: 100%; margin: 0; padding: 0; flex: 1; display: flex; flex-flow: column; overflow: hidden; }
          #main { display: flex; flex: 1; overflow: hidden; }
          #header { background: #e0e0e0; }
          #header h1 { margin: 0.15em }
          #navigation { overflow: auto; height: 100%; width: 30%; }
          #navigation > div { padding: 0.5em; }
          #navigation ul { list-style: none; padding: 0; }
          #navigation ul.groups { margin: 0 0 1em 0.5em; }
          #navigation ul.groups li { margin: 0 0 0.5em; }
          #navigation ul.sections { margin: -1em 0 1em 0em; }
          #documentation { overflow: auto; height: 100%; width: 70%; padding: 0 1em 1em 1em; }
          #documentation h2 { padding: 0.5em 0 0 0; }
          code, tt { font-family: monospace; background-color: #c0c0c0; padding: 0.2em 0.33em 0.2em 0.33em; }
          pre { font-family: monospace; background-color: #c0c0c0; padding: 0.5em; width: 80%; overflow-x: auto; }
          .tabs div:not(:target) { display: none; }
          .tabs div:target { padding-top: 4.5em; margin-top: -4.5em; display: block; }
          .response-code { margin-right: 0.5em; padding: 0.25em; background-color: yellow; }
          .tag { padding-top: 1em; }
          .summary { padding-top: 1em; }
          .get::after { content: "get"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid green; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .post::after { content: "post"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid yellow; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .delete::after { content: "delete"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid red; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .put::after { content: "put"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid orange; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          a { text-decoration: none; }
        </style>
        <div id="wrapper">
          <div id="header">
            <h1><a href="#top">#{@title}</a></h1>
          </div>
          <div id="main">
            <div id="navigation">
              <div>
                #{section_nav}
                #{raw_sections}
              </div>
            </div>
            <div id="documentation">
              <a id="top"/>
              <div>
                #{description ? MyMarkdownRenderer.new.render(description) : "TODO"}
                #{raw_definition_related_requests}
              </div>
            </div>
          </div>
        </div>
      }

      "<!DOCTYPE html><html lang=\"en\"><body>#{raw_body}</body></html>"
    end

    def describe_schema(key, db)
      if key == "$ref" || ref = db["$ref"]
        return describe_schema(nil, @definitions[(ref || db).split("/").last])
      end

      if db.is_a?(Hash)
        unless type = db["type"]
          raise "invalid schema #{[db.class, db].inspect}"
        end
      else
        type = db
      end

      lower_parts = case type
        when "boolean"
          true

        when "string"
          case db["format"]
            when "date-time"
              DateTime.now.rfc3339

          else
            "string"
          end

        when "number"
          case db["format"]
            when "float"
              0.0

          else
            "#{db["format"]} number"
          end

        when "integer", "int32"
          #unless format = db["format"]
          #  raise "invalid integer"
          #end

          0 #TODO: example id links

        when "array"
          unless items = db["items"]
            raise "invalid array"
          end

          [ describe_schema(nil, items) ]
          
        when "object"
          properties = db["properties"]
          additional_properties = db["additionalProperties"]

          unless properties || additional_properties
            raise "invalid object #{db}"
          end

          r = {}

          properties && properties.each { |k, v|
            r.merge!({ k => describe_schema(k, v) })
          }

          i = 0
          additional_properties && additional_properties.each { |k, v|
            2.times {
              i += 1
              r.merge!({ "property#{i}" => describe_schema(k, v) })
            }
          }

          r
      else
        #raise "unknown schema #{db.class} #{db.inspect}"
        ""
      end

      lower_parts
    end

    def parse_specification!
      @specification_bits.each { |bit|
        secondary_bits = @specification[bit]

        case bit
          when "swagger"
            unless secondary_bits == "2.0"
              raise "invalid swagger"
            end

          when "host"
          when "basePath"
          when "schemes"
          when "consumes"
          when "produces"
          when "info"
            @title = secondary_bits["title"]
            @description = secondary_bits["description"]

          when "definitions"
            @definitions = secondary_bits

          when "paths"
            secondary_bits.each { |path, methods|
              methods && methods.each { |method, request|
                if request["tags"]
                  request["tags"].each { |tag|
                    @requests_by_tag[tag] ||= []
                    @requests_by_tag[tag] << [method, request, path]
                  }
                else
                  @requests_by_tag["default"] ||= []
                  @requests_by_tag["default"] << [method, request, path]
                end
              }
            }

          when "tags"
            @tags = secondary_bits 
            @tags && @tags.each { |t|
              @tags_by_name[t["name"]] = t["description"]
            }

          when "x-tagGroups"
            @tags_by_groups = secondary_bits

          when "securityDefinitions"

        else
          raise "unknown swagger"
        end
      }
    end
  end
end
