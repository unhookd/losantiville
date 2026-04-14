#

require "spec_helper"

describe "ARIA attributes and semantic CSS classNames" do
  shared_examples "valid HTML document structure" do
    it "has html element with lang attribute" do
      expect(html).to match(/<html lang="en"/)
    end

    it "has a head element with meta charset" do
      expect(html).to include('<meta charset="UTF-8"/>')
    end

    it "has a theme stylesheet link in head" do
      expect(html).to match(/<link[^>]*id="theme-stylesheet"/)
    end

    it "has theme stylesheet link with rel stylesheet" do
      expect(html).to match(/<link[^>]*rel="stylesheet"/)
    end

    it "has theme stylesheet defaulting to light-theme.css" do
      expect(html).to match(/<link[^>]*href="light-theme.css"/)
    end

    it "has a header element with role banner" do
      expect(html).to match(/<header[^>]*role="banner"/)
    end

    it "has a header element with api-header class" do
      expect(html).to match(/<header[^>]*class="api-header"/)
    end

    it "has an h1 with api-title class" do
      expect(html).to match(/<h1[^>]*class="api-title"/)
    end

    it "has a theme toggle button" do
      expect(html).to match(/<button[^>]*class="theme-toggle"/)
    end

    it "has theme toggle with role switch" do
      expect(html).to match(/<button[^>]*role="switch"/)
    end

    it "has theme toggle with aria-checked" do
      expect(html).to match(/<button[^>]*aria-checked="false"/)
    end

    it "has theme toggle with aria-label" do
      expect(html).to match(/<button[^>]*aria-label="Toggle dark theme"/)
    end

    it "has theme toggle with inline onclick handler" do
      expect(html).to match(/<button[^>]*onclick="/)
    end

    it "has onclick handler that references theme-stylesheet element" do
      expect(html).to include("getElementById('theme-stylesheet')")
    end

    it "has onclick handler that toggles to dark-theme.css" do
      expect(html).to include("dark-theme.css")
    end

    it "has onclick handler that toggles to light-theme.css" do
      expect(html).to include("light-theme.css")
    end

    it "has onclick handler that updates aria-checked" do
      expect(html).to include("aria-checked")
    end

    it "has a nav element with role navigation" do
      expect(html).to match(/<nav[^>]*role="navigation"/)
    end

    it "has a nav element with aria-label" do
      expect(html).to match(/<nav[^>]*aria-label="API navigation"/)
    end

    it "has a nav element with api-navigation class" do
      expect(html).to match(/<nav[^>]*class="api-navigation"/)
    end

    it "has a main element with role main" do
      expect(html).to match(/<main[^>]*role="main"/)
    end

    it "has a main element with aria-label" do
      expect(html).to match(/<main[^>]*aria-label="API documentation"/)
    end

    it "has a main element with api-documentation class" do
      expect(html).to match(/<main[^>]*class="api-documentation"/)
    end

    it "has a wrapper div with role document" do
      expect(html).to match(/<div[^>]*class="api-wrapper"[^>]*role="document"/)
    end

    it "has a div with api-main-content class" do
      expect(html).to include('class="api-main-content"')
    end

    it "has a div with documentation-content class" do
      expect(html).to include('class="documentation-content"')
    end

    it "has a div with nav-content class" do
      expect(html).to include('class="nav-content"')
    end
  end

  shared_examples "semantic operation list markup" do
    it "has operations-group container divs" do
      expect(html).to include('class="operations-group"')
    end

    it "has operations-list with role list" do
      expect(html).to match(/class="operations-list"[^>]*role="list"/)
    end

    it "has operations-list with aria-label" do
      expect(html).to match(/class="operations-list"[^>]*aria-label="API operations"/)
    end

    it "has operation-item list items with role listitem" do
      expect(html).to match(/class="operation-item"[^>]*role="listitem"/)
    end

    it "has endpoint-path paragraphs" do
      expect(html).to include('class="endpoint-path"')
    end

    it "has http-method styled tt elements" do
      expect(html).to match(/class="http-method http-method--\w+"/)
    end

    it "has endpoint-url tt elements" do
      expect(html).to include('class="endpoint-url"')
    end

    it "has response-tabs with role tablist" do
      expect(html).to match(/class="tabs response-tabs"[^>]*role="tablist"/)
    end

    it "has response-tabs with aria-label" do
      expect(html).to match(/class="tabs response-tabs"[^>]*aria-label="Response codes"/)
    end

    it "has response-code links with role tab" do
      expect(html).to match(/class="response-code"[^>]*role="tab"/)
    end

    it "has response-code links with aria-controls" do
      expect(html).to match(/class="response-code"[^>]*role="tab"[^>]*aria-controls=/)
    end

    it "has response-panel divs with role tabpanel" do
      expect(html).to match(/class="response-panel"[^>]*role="tabpanel"/)
    end

    it "has schema-preview pre elements with aria-label" do
      expect(html).to match(/class="schema-preview"[^>]*aria-label="Response schema for/)
    end

    it "has tag-description paragraphs" do
      expect(html).to include('class="tag-description"')
    end
  end

  context "with Swagger 2.0 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../../api-with-examples.yaml", __FILE__)
      ))
    end
    let(:html) { renderer.render }

    include_examples "valid HTML document structure"
    include_examples "semantic operation list markup"
  end

  context "with OpenAPI 3.0 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi3_example.yaml", __FILE__)
      ))
    end
    let(:html) { renderer.render }

    include_examples "valid HTML document structure"
    include_examples "semantic operation list markup"

    context "servers section" do
      it "has servers div with role region" do
        expect(html).to match(/class="servers"[^>]*role="region"/)
      end

      it "has servers div with aria-label" do
        expect(html).to match(/class="servers"[^>]*aria-label="Server information"/)
      end

      it "has servers-heading class on heading" do
        expect(html).to include('class="servers-heading"')
      end

      it "has servers-list with role list" do
        expect(html).to match(/class="servers-list"[^>]*role="list"/)
      end

      it "has server-item list items with role listitem" do
        expect(html).to match(/class="server-item"[^>]*role="listitem"/)
      end

      it "has server-url class on server URLs" do
        expect(html).to include('class="server-url"')
      end
    end

    context "request body section" do
      it "has request-body div with role region" do
        expect(html).to match(/class="request-body"[^>]*role="region"/)
      end

      it "has request-body div with aria-label" do
        expect(html).to match(/class="request-body"[^>]*aria-label="Request body"/)
      end

      it "has request-body-heading class" do
        expect(html).to include('class="request-body-heading"')
      end

      it "has request-body-description class" do
        expect(html).to include('class="request-body-description"')
      end

      it "has request-body-required class" do
        expect(html).to include('class="request-body-required"')
      end

      it "has media-type class on media type paragraphs" do
        expect(html).to include('class="media-type"')
      end

      it "has media-type-label class" do
        expect(html).to include('class="media-type-label"')
      end

      it "has schema-preview with aria-label for request body" do
        expect(html).to match(/class="schema-preview"[^>]*aria-label="Request body schema"/)
      end
    end

    context "security schemes section" do
      it "has security-schemes div with role region" do
        expect(html).to match(/class="security-schemes"[^>]*role="region"/)
      end

      it "has security-schemes div with aria-label" do
        expect(html).to match(/class="security-schemes"[^>]*aria-label="Security schemes"/)
      end

      it "has security-schemes-heading class" do
        expect(html).to include('class="security-schemes-heading"')
      end

      it "has security-schemes-list with role list" do
        expect(html).to match(/class="security-schemes-list"[^>]*role="list"/)
      end

      it "has security-scheme-item with role listitem" do
        expect(html).to match(/class="security-scheme-item"[^>]*role="listitem"/)
      end

      it "has scheme-name class" do
        expect(html).to include('class="scheme-name"')
      end

      it "has scheme-type class" do
        expect(html).to include('class="scheme-type"')
      end
    end

    context "deprecated operations" do
      it "has aria-label on deprecated operation items" do
        expect(html).to match(/aria-label="Deprecated endpoint"/)
      end
    end
  end

  context "with OpenAPI 3.1 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi31_example.yaml", __FILE__)
      ))
    end
    let(:html) { renderer.render }

    include_examples "valid HTML document structure"
    include_examples "semantic operation list markup"

    context "webhooks section" do
      it "has webhooks-group container divs" do
        expect(html).to include('class="webhooks-group"')
      end

      it "has webhooks-list with role list" do
        expect(html).to match(/class="webhooks-list"[^>]*role="list"/)
      end

      it "has webhooks-list with aria-label" do
        expect(html).to match(/class="webhooks-list"[^>]*aria-label="Webhook operations"/)
      end

      it "has webhook-item list items with role listitem" do
        expect(html).to match(/class="webhook-item"[^>]*role="listitem"/)
      end

      it "has webhook-badge with aria-label" do
        expect(html).to match(/class="webhook-badge"[^>]*aria-label="Webhook"/)
      end

      it "has http-method classes on webhook endpoints" do
        expect(html).to match(/class="http-method http-method--post"/)
      end

      it "has endpoint-url classes on webhook names" do
        expect(html).to include('class="endpoint-url"')
      end

      it "has response-tabs in webhooks with role tablist" do
        # Webhook responses should also be tabbed
        expect(html).to match(/class="tabs response-tabs"[^>]*role="tablist"[^>]*aria-label="Response codes"/)
      end
    end
  end

  context "with minimal OpenAPI 3.1 spec" do
    let(:renderer) do
      Losantiville::Renderer.new(File.open(
        File.expand_path("../../../fixtures/openapi31_minimal.yaml", __FILE__)
      ))
    end
    let(:html) { renderer.render }

    include_examples "valid HTML document structure"
    include_examples "semantic operation list markup"

    it "has request-body region even for minimal specs" do
      expect(html).to match(/class="request-body"[^>]*role="region"/)
    end
  end

  context "application landing page", type: :request do
    # Override the app method for Rack::Test since described_class is a string here
    def app
      Losantiville::Application
    end

    it "has aria-label on the form" do
      get "/"
      expect(last_response.body).to match(/aria-label="Upload API specification"/)
    end

    it "has specification-upload-form class on form" do
      get "/"
      expect(last_response.body).to include('class="specification-upload-form"')
    end

    it "has aria-label on file input" do
      get "/"
      expect(last_response.body).to match(/aria-label="Choose specification file"/)
    end

    it "has aria-label on submit button" do
      get "/"
      expect(last_response.body).to match(/aria-label="Upload specification"/)
    end

    it "has app-container class on outer container" do
      get "/"
      expect(last_response.body).to include('class="app-container"')
    end

    it "has role application on outer container" do
      get "/"
      expect(last_response.body).to match(/role="application"/)
    end

    it "has dashboard-container class" do
      get "/"
      expect(last_response.body).to include('class="dashboard-container"')
    end

    it "has file-input class on file input" do
      get "/"
      expect(last_response.body).to include('class="file-input"')
    end

    it "has submit-button class on submit" do
      get "/"
      expect(last_response.body).to include('class="submit-button"')
    end
  end
end
