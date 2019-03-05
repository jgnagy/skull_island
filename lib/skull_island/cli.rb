# frozen_string_literal: true

# Internal requirements
require 'skull_island'

# External requirements
require 'yaml'
require 'erubi'
require 'thor'

module SkullIsland
  # Base CLI for SkullIsland
  class CLI < Thor
    class_option :verbose, type: :boolean

    desc 'export [OPTIONS] OUTPUT_FILE', 'Export the current configuration to OUTPUT_FILE'
    def export(output_file)
      full_filename = File.expand_path(output_file)
      dirname = File.dirname(full_filename)
      unless File.exist?(dirname) && File.ftype(dirname) == 'directory'
        raise Exceptions::InvalidArguments, "#{full_filename} is invalid"
      end

      output = { 'version' => '0.14' }

      [
        Resources::Consumer,
        Resources::Service,
        Resources::Upstream,
        Resources::Plugin
      ].each { |clname| export_class(clname, output) }

      File.write(full_filename, output.to_yaml)
    end

    desc 'import [OPTIONS] INPUT_FILE', 'Import a configuration from INPUT_FILE'
    option :exclusive, type: :boolean, desc: 'Remove ALL other configuration (default false)'
    def import(input_file)
      full_filename = File.expand_path(input_file)
      unless File.exist?(full_filename) && File.ftype(full_filename) == 'file'
        raise Exceptions::InvalidArguments, "#{full_filename} is invalid"
      end

      raw ||= begin
            File.read(full_filename)
              rescue StandardError => e
                raise "Unable to process #{relative_path}: #{e.message}"
          end
      unrubied_yaml = eval(Erubi::Engine.new(raw).src)

      input = YAML.load_file(unrubied_yaml)

      [
        Resources::Consumer,
        Resources::Service,
        Resources::Upstream,
        Resources::Plugin
      ].each { |clname| input_class(clname, input) }
    end

    private

    def export_class(class_name, output_data)
      STDERR.puts "[INFO] Processing #{class_name.route_key}" if options['verbose']
      output_data[class_name.route_key] = class_name.all.collect(&:to_hash)
    end

    def import_class(class_name, import_data)
      STDERR.puts "[INFO] Processing #{class_name.route_key}" if options['verbose']
      class_name.batch_import(import_data[class_name.route_key], verbose: options['verbose'])
    end
  end
end
