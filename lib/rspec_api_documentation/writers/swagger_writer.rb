require 'rspec_api_documentation/writers/formatter'

module RspecApiDocumentation
  module Writers
    class SwaggerWriter < Writer
      delegate :docs_dir, :to => :configuration

      def write
        File.open(docs_dir.join("swagger.json"), "w+") do |f|
          f.write Formatter.to_json(render_template)
        end
      end

      def render_template
        SwaggerTemplate.new(index, configuration)
      end
    end

    class SwaggerTemplate

      def initialize(index, configuration)
        @index = index
        @configuration = configuration
      end

      def as_json
        paths = add_paths
        definitions = add_definitions
        hash = {
          swagger: '2.0',
          info: {
            version: '0.0.1',
            title: @configuration.api_name
          }
        }
        hash[:paths] = paths if paths.present?
        hash[:definitions] = definitions if definitions.present?
        hash
      end

      private

      def add_definitions
        examples.map{|x| x[:definitions]}.uniq[0]
      end

      def add_paths
        hash = {}
        examples.group_by{|x| x[:route] }.each do |path, path_examples|
          normalized_path = normalize_path(path)
          hash[normalized_path] = {}
          path_examples.group_by{|x| x[:method]}.each do |method, method_example|
            hash[normalized_path][method] = example_to_swagger(method_example[0])
          end
        end

        hash
      end

      def normalize_path(path)
        path.split('/').map do |item|
          if item.start_with?(':')
            "{#{item.gsub(':', '')}}"
          else
            item
          end
        end.join('/')
      end

      def example_to_swagger(example)
        # TODO: Probably need all the examples for a method and path and merge
        # the data in some way
        {
          summary: example[:description],
          description: example[:full_description],
          parameters: add_parameters(example[:parameters]),
          responses: add_responses(example[:requests]),
          consumes: add_consumes(example)
        }
      end

      def add_consumes(example)
        [
          example[:headers]['Content-Type']
        ]
      end

      def add_parameters(parameters)
        arr = []
        if parameters.present?
          parameters.each do |parameter|
            hash = {}
            hash[:type] = parameter[:type] if parameter[:type].present?
            hash[:format] = parameter[:format] if parameter[:format].present?
            hash[:in] = parameter.fetch(:in, :query)
            hash[:required] = parameter.fetch(:required, true)
            hash[:name] = parameter[:name]
            hash[:description] = parameter[:description]
            hash[:schema] = parameter[:schema] if parameter[:schema].present?
            arr << hash
          end
        end
        arr
      end

      def add_responses(requests)
        hash = {}
        requests.each do |request|
          hash[request[:response_status]] = { description: request[:response_status_text]}
        end
        hash
      end

      def examples
        @examples ||= @index.examples.map(&:metadata)
      end
    end
  end
end