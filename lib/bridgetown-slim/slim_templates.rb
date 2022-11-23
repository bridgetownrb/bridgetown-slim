# frozen_string_literal: true

require "slim"

module Bridgetown
  class SlimView < RubyTemplateView
    def partial(partial_name, options = {})
      options.merge!(options[:locals]) if options[:locals]

      partial_segments = partial_name.split("/")
      partial_segments.last.sub!(%r!^!, "_")
      partial_name = partial_segments.join("/")

      search_directories = [site.config[:partials_dir], site.config[:components_dir]]
      partial_file = nil

      if partial_name.start_with?(*search_directories)
        partial_file = site.in_source_dir("#{partial_name}.slim")
      else
        for directory in search_directories
          partial_file = site.in_source_dir(directory, "#{partial_name}.slim")
          if File.exists?(partial_file)
            break 
          else
            partial_file = nil
          end
        end
      end

      partial_file = site.in_source_dir("#{partial_name}.slim") if partial_file == nil

      Slim::Template.new(partial_file).render(self, options)
    end

    def asset_path(asset_type)
      Bridgetown::Utils.parse_frontend_manifest_file(site, asset_type.to_s)
    end
  end

  module Converters
    class SlimTemplates < Converter
      priority :highest
      input :slim

      # Logic to do the Slim content conversion.
      #
      # @param content [String] Content of the file (without front matter).
      # @params convertible [Bridgetown::Page, Bridgetown::Document, Bridgetown::Layout]
      #   The instantiated object which is processing the file.
      #
      # @return [String] The converted content.
      def convert(content, convertible)
        return content if convertible.data[:template_engine] != "slim"

        slim_view = Bridgetown::SlimView.new(convertible)

        slim_renderer = Slim::Template.new(convertible.relative_path) { content }

        if convertible.is_a?(Bridgetown::Layout)
          slim_renderer.render(slim_view) do
            convertible.current_document_output
          end
        else
          slim_renderer.render(slim_view)
        end
      end

      def matches(ext, convertible)
        return true if convertible.data[:template_engine] == "slim"

        super(ext).tap do |ext_matches|
          convertible.data[:template_engine] = "slim" if ext_matches
        end
      end

      def output_ext(ext)
        ext == ".slim" ? ".html" : ext
      end
    end
  end
end
