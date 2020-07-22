# frozen_string_literal: true

require "tilt/erb"
require "slim"

module Bridgetown
  class SlimView < RubyTemplateView
    def partial(partial_name, options = {})
      options.merge!(options[:locals]) if options[:locals]

      partial_segments = partial_name.split("/")
      partial_segments.last.sub!(%r!^!, "_")
      partial_name = partial_segments.join("/")

      Slim::Template.new(
        site.in_source_dir(site.config[:partials_dir], "#{partial_name}.slim")
      ).render(self, options)
    end
  end

  module Converters
    class SlimTemplates < Converter
      input :slim

      # Logic to do the Slim content conversion.
      #
      # @param content [String] Content of the file (without front matter).
      # @params convertible [Bridgetown::Page, Bridgetown::Document, Bridgetown::Layout]
      #   The instantiated object which is processing the file.
      #
      # @return [String] The converted content.
      def convert(content, convertible)
        slim_view = Bridgetown::SlimView.new(convertible)

        slim_renderer = Slim::Template.new { content }

        if convertible.is_a?(Bridgetown::Layout)
          slim_renderer.render(slim_view) do
            convertible.current_document_output
          end
        else
          slim_renderer.render(slim_view)
        end
      end
    end
  end
end
