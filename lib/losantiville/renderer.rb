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
      raw = Psych.load(specification_io)
      @spec = SpecificationDetector.detect_and_parse(raw)

      @title = @spec.title
      @description = @spec.description
      @definitions = @spec.schemas
      @requests_by_tag = @spec.requests_by_tag
      @tags_by_name = @spec.tags_by_name
      @tags_by_groups = @spec.tags_by_groups
      @sections = {}
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

      section_nav = %q{<ul class="sections" role="list" aria-label="Document sections">}
      @sections.each { |section, href|
        section_nav += %Q{<li role="listitem"><h3><a href="#{href}">#{section}</a></h3></li>}
      }
      section_nav += %q{</ul>}

      raw_definition_related_requests = ""

      # Render servers if present (OpenAPI 3.x)
      if @spec.servers && !@spec.servers.empty?
        raw_definition_related_requests += render_servers
      end

      @requests_by_tag.each { |rk_tag, related_requests|
        raw_definition_related_requests += %Q{
          <h3 class="tag" id="tag-#{rk_tag.gsub(" ", "-")}">
            <a href="#tag-#{rk_tag.gsub(" ", "-")}">#{rk_tag}</a>
          </h3>
          <p class="tag-description">#{@tags_by_name[rk_tag] ? CommonMarker.render_html(@tags_by_name[rk_tag]) : 'no-tag'}</p>
        }

        raw_definition_related_requests += %q{<div class="operations-group"><ul class="operations-list" role="list" aria-label="API operations">}
        related_requests.each { |related_method, related_request, related_path|
          deprecated_class = related_request["deprecated"] ? " deprecated" : ""
          deprecated_aria = related_request["deprecated"] ? ' aria-label="Deprecated endpoint"' : ""
          raw_definition_related_requests += %Q{
            <li class="operation-item" role="listitem"#{deprecated_aria}>
              <h5 class="summary#{deprecated_class}" id="summary-#{rk_tag}-#{related_method}-#{related_path}">
                <a href="#summary-#{rk_tag}-#{related_method}-#{related_path}">#{related_request["summary"]}</a>
              </h5>
              #{related_request["description"] ? CommonMarker.render_html(related_request["description"], :DEFAULT) : ""}
              <p class="endpoint-path">
                <tt class="http-method http-method--#{related_method}">#{related_method.upcase}</tt> <tt class="endpoint-url">#{related_path}</tt>
              </p>
          }

          # Render request body if present (OpenAPI 3.x)
          if related_request["requestBody"]
            raw_definition_related_requests += render_request_body(related_request["requestBody"])
          end

          all_requests_paths_bits = %q{}
          all_requests_paths_tabs = %q{}
          all_requests_paths_bits += %q{<div class="tabs response-tabs" role="tablist" aria-label="Response codes">}

          related_request["responses"].each { |code, response|
            all_requests_paths_tabs += %Q{<a class="response-code" role="tab" aria-controls="#{related_method}-#{related_path}-#{code}" href="##{related_method}-#{related_path}-#{code}">#{code}</a>}

            all_requests_paths_bits += %Q{<div class="response-panel" role="tabpanel" id="#{related_method}-#{related_path}-#{code}"><pre class="schema-preview" aria-label="Response schema for #{code}">}
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

      # Render webhooks if present (OpenAPI 3.1)
      if @spec.webhooks_by_tag && !@spec.webhooks_by_tag.empty?
        raw_definition_related_requests += render_webhooks
      end

      # Render security schemes if present
      if @spec.security_schemes && !@spec.security_schemes.empty?
        raw_definition_related_requests += render_security_schemes
      end

      raw_sections = ""

      @tags_by_groups && @tags_by_groups.each { |group_item|
        group = group_item["name"]
        tags = group_item["tags"]

        raw_sections += %Q{<h4 class="tag-group-heading" id="group-#{group.gsub(" ", "-")}"><a href="#group-#{group.gsub(" ", "-")}">#{group}</a></h4>}

        tags.each { |api_tag|
          raw_request_summaries = []

          if requests_by_tag = @requests_by_tag[api_tag]
            raw_sections += %Q{<h5 class="tag-heading"><a href="#tag-#{api_tag.gsub(" ", "-")}">#{api_tag}</a></h5>}

            requests_by_tag.each { |method, request, path|
              raw_request_summaries << %Q{<li class="nav-operation-item" role="listitem">} +
              %Q{<a class="nav-operation-link #{method}" href="#summary-#{request["tags"].first}-#{method}-#{path}">#{request["summary"]}</a>} +
              %q{</li>}
            }
          end

          raw_sections += %q{<ul class="groups" role="list" aria-label="Operations">} + raw_request_summaries.join + "</ul>"
        }
      }

      raw_body = %Q{
        <style>
          html { font-family: sans-serif; font-size: smaller; }
          html, body, #outside-container, #dashboard-container, .api-wrapper { height: 100%; margin: 0; padding: 0; flex: 1; display: flex; flex-flow: column; overflow: hidden; }
          .api-main-content { display: flex; flex: 1; overflow: hidden; }
          .api-header { background: #e0e0e0; display: flex; align-items: center; justify-content: space-between; }
          .api-header h1 { margin: 0.15em }
          .theme-toggle { cursor: pointer; border: 1px solid #999; border-radius: 3px; padding: 0.25em 0.75em; font-size: 0.8em; background: #fff; margin-right: 0.5em; }
          .api-navigation { overflow: auto; height: 100%; width: 30%; }
          .api-navigation > div { padding: 0.5em; }
          .api-navigation ul { list-style: none; padding: 0; }
          .api-navigation ul.groups { margin: 0 0 1em 0.5em; }
          .api-navigation ul.groups li { margin: 0 0 0.5em; }
          .api-navigation ul.sections { margin: -1em 0 1em 0em; }
          .api-documentation { overflow: auto; height: 100%; width: 70%; padding: 0 1em 1em 1em; }
          .api-documentation h2 { padding: 0.5em 0 0 0; }
          code, tt { font-family: monospace; background-color: #c0c0c0; padding: 0.2em 0.33em 0.2em 0.33em; }
          pre { font-family: monospace; background-color: #c0c0c0; padding: 0.5em; width: 80%; overflow-x: auto; }
          .response-tabs .response-panel:not(:target) { display: none; }
          .response-tabs .response-panel:target { padding-top: 4.5em; margin-top: -4.5em; display: block; }
          .response-code { margin-right: 0.5em; padding: 0.25em; background-color: yellow; }
          .tag { padding-top: 1em; }
          .summary { padding-top: 1em; }
          .deprecated a { text-decoration: line-through; }
          .get::after { content: "get"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid green; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .post::after { content: "post"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid yellow; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .delete::after { content: "delete"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid red; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .put::after { content: "put"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid orange; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .patch::after { content: "patch"; font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid purple; border-radius: 3px; padding: 0em 0.33em 0 0.33em; }
          .servers { margin: 0 0 1em 0; padding: 0.5em; background: #f0f0f0; }
          .servers tt { background: none; }
          .request-body { margin: 0.5em 0; padding: 0.5em; background: #f8f8f0; }
          .webhook-badge { font-size: 0.7em; margin: 0em 0.7em 0 0.7em; border: 1px solid #9b59b6; border-radius: 3px; padding: 0em 0.33em 0 0.33em; color: #9b59b6; }
          .security-schemes { margin: 1em 0; padding: 0.5em; background: #f0f8f0; }
          a { text-decoration: none; }
        </style>
        <div class="api-wrapper" role="document">
          <header class="api-header" role="banner">
            <h1 class="api-title"><a href="#top">#{@title}</a></h1>
            <button class="theme-toggle" role="switch" aria-checked="false" aria-label="Switch to dark theme" onclick="(function(btn){var link=document.getElementById('theme-stylesheet');var isDark=link.getAttribute('href')==='dark-theme.css';link.setAttribute('href',isDark?'light-theme.css':'dark-theme.css');btn.setAttribute('aria-checked',String(!isDark));btn.setAttribute('aria-label',isDark?'Switch to dark theme':'Switch to light theme');btn.textContent=isDark?'\\u263E Dark':'\\u2600 Light';})(this)">&#x263E; Dark</button>
          </header>
          <div class="api-main-content">
            <nav class="api-navigation" role="navigation" aria-label="API navigation">
              <div class="nav-content">
                #{section_nav}
                #{raw_sections}
              </div>
            </nav>
            <main class="api-documentation" role="main" aria-label="API documentation">
              <a id="top"/>
              <div class="documentation-content">
                #{description ? MyMarkdownRenderer.new.render(description) : "TODO"}
                #{raw_definition_related_requests}
              </div>
            </main>
          </div>
        </div>
      }

      "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"/><link id=\"theme-stylesheet\" rel=\"stylesheet\" href=\"light-theme.css\"/></head><body>#{raw_body}</body></html>"
    end

    def describe_schema(key, db, seen = nil)
      seen ||= {}

      if key == "$ref" || (db.is_a?(Hash) && (ref = db["$ref"]))
        ref_string = ref || db
        # Cycle detection
        if seen[ref_string]
          return "(circular ref)"
        end
        seen[ref_string] = true

        resolved = @spec.resolve_ref(ref_string)
        unless resolved
          # Fallback: try splitting on last segment (backward compat)
          resolved = @definitions[(ref_string).split("/").last]
        end
        return describe_schema(nil, resolved, seen) if resolved
        return "(unresolved ref: #{ref_string})"
      end

      return "" unless db

      # Handle allOf / anyOf / oneOf composition
      if db.is_a?(Hash)
        if db["allOf"]
          return describe_all_of(db["allOf"], seen)
        end
        if db["oneOf"]
          return describe_one_of(db["oneOf"], seen)
        end
        if db["anyOf"]
          return describe_any_of(db["anyOf"], seen)
        end
      end

      if db.is_a?(Hash)
        type = db["type"]
        # OpenAPI 3.1: type can be an array, e.g. ["string", "null"]
        if type.is_a?(Array)
          type = type.reject { |t| t == "null" }.first || type.first
        end
        #unless type
        #  raise "invalid schema #{[db.class, db].inspect}"
        #end
      else
        type = db
      end

      lower_parts = case type
        when "boolean"
          true

        when "string"
          case db.is_a?(Hash) ? db["format"] : nil
            when "date-time"
              DateTime.now.rfc3339

          else
            "string"
          end

        when "number"
          case db.is_a?(Hash) ? db["format"] : nil
            when "float"
              0.0

          else
            format_str = db.is_a?(Hash) ? db["format"] : nil
            "#{format_str} number"
          end

        when "integer", "int32"
          0 #TODO: example id links

        when "array"
          items = db.is_a?(Hash) ? db["items"] : nil
          unless items
            raise "invalid array"
          end

          [ describe_schema(nil, items, seen) ]
          
        when "object"
          properties = db.is_a?(Hash) ? db["properties"] : nil
          additional_properties = db.is_a?(Hash) ? db["additionalProperties"] : nil

          #unless properties || additional_properties
          #  raise "invalid object #{db}"
          #end

          r = {}

          properties && properties.each { |k, v|
            r.merge!({ k => describe_schema(k, v, seen) })
          }

          i = 0
          additional_properties && additional_properties.is_a?(Hash) && additional_properties.each { |k, v|
            2.times {
              i += 1
              r.merge!({ "property#{i}" => describe_schema(k, v, seen) })
            }
          }

          r

        when "null"
          nil

      else
        ""
      end

      lower_parts
    end

    private

    def render_servers
      html = %q{<div class="servers" role="region" aria-label="Server information"><h4 class="servers-heading">Servers</h4><ul class="servers-list" role="list">}
      @spec.servers.each do |server|
        desc = server["description"] ? " - #{server["description"]}" : ""
        html += %Q{<li class="server-item" role="listitem"><tt class="server-url">#{server["url"]}</tt>#{desc}</li>}
      end
      html += %q{</ul></div>}
      html
    end

    def render_request_body(request_body)
      return "" unless request_body
      html = %q{<div class="request-body" role="region" aria-label="Request body"><h6 class="request-body-heading">Request Body</h6>}

      if request_body["description"]
        html += %Q{<p class="request-body-description">#{request_body["description"]}</p>}
      end

      if request_body["required"]
        html += %q{<p class="request-body-required"><em>Required</em></p>}
      end

      content = request_body["content"]
      if content.is_a?(Hash)
        content.each do |media_type, media_obj|
          html += %Q{<p class="media-type"><tt class="media-type-label">#{media_type}</tt></p>}
          if media_obj.is_a?(Hash) && media_obj["schema"]
            begin
              html += %Q{<pre class="schema-preview" aria-label="Request body schema">} + JSON.pretty_generate(describe_schema("schema", media_obj["schema"])) + "</pre>"
            rescue => e
              html += %Q{<pre class="schema-preview schema-error">#{e.message}</pre>}
            end
          end
        end
      end

      html += %q{</div>}
      html
    end

    def render_webhooks
      html = %Q{<h3 class="tag" id="tag-webhooks"><a href="#tag-webhooks">Webhooks</a></h3>}
      @spec.webhooks_by_tag.each do |tag, webhook_ops|
        html += %q{<div class="webhooks-group"><ul class="webhooks-list" role="list" aria-label="Webhook operations">}
        webhook_ops.each do |method, operation, name|
          html += %Q{
            <li class="webhook-item" role="listitem">
              <h5 class="summary" id="webhook-#{name}-#{method}">
                <a href="#webhook-#{name}-#{method}">#{operation["summary"] || name}</a>
                <span class="webhook-badge" aria-label="Webhook">webhook</span>
              </h5>
              #{operation["description"] ? CommonMarker.render_html(operation["description"], :DEFAULT) : ""}
              <p class="endpoint-path">
                <tt class="http-method http-method--#{method}">#{method.upcase}</tt> <tt class="endpoint-url">#{name}</tt>
              </p>
          }

          # Render responses
          if operation["responses"]
            html += %q{<div class="tabs response-tabs" role="tablist" aria-label="Response codes">}
            operation["responses"].each do |code, response|
              html += %Q{<a class="response-code" role="tab" aria-controls="webhook-#{name}-#{method}-#{code}" href="#webhook-#{name}-#{method}-#{code}">#{code}</a>}
            end
            operation["responses"].each do |code, response|
              html += %Q{<div class="response-panel" role="tabpanel" id="webhook-#{name}-#{method}-#{code}"><pre class="schema-preview" aria-label="Response schema for #{code}">}
              if response["schema"]
                begin
                  html += JSON.pretty_generate(describe_schema("schema", response["schema"]))
                rescue => e
                  html += e.message
                end
              end
              html += %Q{</pre></div>}
            end
            html += %q{</div>}
          end

          html += %q{</li>}
        end
        html += %q{</ul></div>}
      end
      html
    end

    def render_security_schemes
      html = %q{<div class="security-schemes" role="region" aria-label="Security schemes"><h4 class="security-schemes-heading">Security Schemes</h4><ul class="security-schemes-list" role="list">}
      @spec.security_schemes.each do |name, scheme|
        next unless scheme.is_a?(Hash)
        scheme_type = scheme["type"] || "unknown"
        desc = scheme["description"] ? " - #{scheme["description"]}" : ""
        html += %Q{<li class="security-scheme-item" role="listitem"><strong class="scheme-name">#{name}</strong> (<span class="scheme-type">#{scheme_type}</span>)#{desc}</li>}
      end
      html += %q{</ul></div>}
      html
    end

    def describe_all_of(schemas, seen)
      r = {}
      schemas.each do |sub|
        result = describe_schema(nil, sub, seen.dup)
        if result.is_a?(Hash)
          r.merge!(result)
        end
      end
      r
    end

    def describe_one_of(schemas, seen)
      # Return the first variant
      schemas.each do |sub|
        result = describe_schema(nil, sub, seen.dup)
        return result if result
      end
      ""
    end

    def describe_any_of(schemas, seen)
      # Return the first variant
      schemas.each do |sub|
        result = describe_schema(nil, sub, seen.dup)
        return result if result
      end
      ""
    end
  end
end
