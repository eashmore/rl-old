require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'

require_relative "./session"

module RailsLite
  class ControllerBase
    attr_reader :req, :res

    # Setup the controller
    def initialize(req, res, route_params = {})
      @req = req
      @res = res
      @params = Params.new(req, route_params)
      @already_built_response = false
    end

    # Helper method to alias @already_built_response
    def already_built_response?
      @already_built_response
    end

    # Set the response status code and header
    def redirect_to(url)
      raise "double render error" if @already_built_response

      @res.status = 302
      @res["Location"] = url

      @already_built_response = true
      session.store_session(@res)

      nil
    end

    # Populate the response with content.
    # Set the response's content type to the given type.
    # Raise an error if the developer tries to double render.
    def render_content(content, content_type)
      raise "double render error" if @already_built_response

      @res.body = content
      @res.content_type = content_type

      @already_built_response = true

      session.store_session(@res)
      nil
    end
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    path = File.dirname(__FILE__)
    filename = File.join(path, "..", "..", "views",
      self.class.name.underscore, "#{template_name}.html.erb"
    )

    template_code = File.read(filename)

    render_content(ERB.new(template_code).result(binding), "text/html")
  end

  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?

    nil
  end
end
