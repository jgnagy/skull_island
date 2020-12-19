# frozen_string_literal: true

# Internal requirements
require 'skull_island'

# External requirements
require 'yaml'
require 'thor'

module SkullIsland
  # Base CLI for SkullIsland
  class CLI < Thor
    include Helpers::Migration
    include Helpers::CliErb

    class_option :verbose, type: :boolean

    desc 'export [OPTIONS] [OUTPUT|-]', 'Export the current configuration to OUTPUT'
    option :project, desc: 'Project identifier for metadata'
    def export(output_file = '-')
      if output_file == '-'
        warn '[INFO] Outputting to STDOUT' if options['verbose']
      else
        full_filename = File.expand_path(output_file)
        dirname = File.dirname(full_filename)
        unless File.exist?(dirname) && File.ftype(dirname) == 'directory'
          raise Exceptions::InvalidArguments, "#{full_filename} is invalid"
        end
      end

      validate_server_version

      output = { 'version' => '2.2' }
      output['project'] = options['project'] if options['project']

      [
        Resources::CACertificate,
        Resources::Certificate,
        Resources::Consumer,
        Resources::Upstream,
        Resources::Service,
        Resources::Plugin
      ].each { |clname| export_class(clname, output) }

      if output_file == '-'
        STDOUT.puts output.to_yaml
      else
        File.write(full_filename, output.to_yaml)
      end
    end

    desc 'import [OPTIONS] [INPUT|-]', 'Import a configuration from INPUT'
    option :project, desc: 'Project identifier for metadata'
    option :test, type: :boolean, desc: "Don't do anything, just show what would happen"
    def import(input_file = '-')
      raw ||= acquire_input(input_file, options['verbose'])

      # rubocop:disable Security/YAMLLoad
      input = YAML.load(erb_preprocess(raw))
      # rubocop:enable Security/YAMLLoad

      validate_config_version input['version']

      import_time = Time.now.utc.to_i
      input['project'] = options['project'] if options['project']

      [
        Resources::CACertificate,
        Resources::Certificate,
        Resources::Consumer,
        Resources::Upstream,
        Resources::Service,
        Resources::Plugin
      ].each do |clname|
        input[clname.route_key] = [] unless input[clname.route_key] # enforce all top-level keys
        import_class(clname, input, import_time)
      end
    end

    desc(
      'migrate [OPTIONS] [INPUT|-] [OUTPUT|-]',
      'Migrate an older config from INPUT to OUTPUT'
    )
    option :project, desc: 'Project identifier for metadata'
    def migrate(input_file = '-', output_file = '-')
      raw ||= acquire_input(input_file, options['verbose'])

      # rubocop:disable Security/YAMLLoad
      input = YAML.load(raw)
      # rubocop:enable Security/YAMLLoad

      validate_migrate_version input['version']

      output = migrate_config(input)
      output['project'] = options['project'] if options['project']

      if output_file == '-'
        warn '[INFO] Outputting to STDOUT' if options['verbose']
        STDOUT.puts output.to_yaml
      else
        full_filename = File.expand_path(output_file)
        dirname = File.dirname(full_filename)
        unless File.exist?(dirname) && File.ftype(dirname) == 'directory'
          raise Exceptions::InvalidArguments, "#{full_filename} is invalid"
        end

        File.write(full_filename, output.to_yaml)
      end
    end

    desc('reset', 'Fully reset a gateway (removing all config)')
    option :force, type: :boolean, desc: 'Force the reset (required)'
    option :project, desc: 'Project identifier for metadata'
    def reset
      unless options['force']
        puts '[ERR] Missing --force flag.'
        exit 2
      end

      if options['project'] && options['verbose']
        warn "[WARN] ! Resetting gateway for project '#{options['project']}'"
      elsif options['verbose']
        warn '[WARN] ! FULLY Resetting gateway'
      end
      [
        Resources::CACertificate,
        Resources::Certificate,
        Resources::Consumer,
        Resources::Upstream,
        Resources::Service,
        Resources::Plugin
      ].each { |clname| reset_class(clname, options['project']) }
    end

    desc('version', 'Display the current installed version of skull_island')
    def version
      puts "SkullIsland Version: #{SkullIsland::VERSION}"
      exit 1
    end

    private

    def export_class(class_name, output_data)
      warn "[INFO] Processing #{class_name.route_key}" if options['verbose']
      output_data[class_name.route_key] = if options['project']
                                            class_name.where(:project, options['project'])
                                                      .collect(&:export)
                                          else
                                            class_name.all.collect(&:export)
                                          end
    end

    def import_class(class_name, import_data, import_time)
      warn "[INFO] Processing #{class_name.route_key}" if options['verbose']
      class_name.batch_import(
        import_data[class_name.route_key],
        verbose: options['verbose'],
        test: options['test'],
        time: import_time,
        project: import_data['project']
      )
    end

    def reset_class(class_name, project)
      warn "[WARN] ! Resetting #{class_name.route_key}" if options['verbose']
      resources = project ? class_name.all.select { |r| r.project == project } : class_name.all

      resources.each do |resource|
        puts "[WARN] ! Removing #{class_name.name} (#{resource.id})"
        resource.destroy
      end
    end

    # Used to pull input from either STDIN or the specified file
    def acquire_input(input_file, verbose = false)
      if input_file == '-'
        warn '[INFO] Reading from STDIN' if verbose
        STDIN.read
      else
        full_filename = File.expand_path(input_file)
        unless File.exist?(full_filename) && File.ftype(full_filename) == 'file'
          raise Exceptions::InvalidArguments, "#{full_filename} is invalid"
        end

        begin
          File.read(full_filename)
        rescue StandardError => e
          raise "Unable to process #{relative_path}: #{e.message}"
        end
      end
    end

    def validate_config_version(version)
      if version && ['1.1', '1.2', '1.4', '1.5', '2.0', '2.1', '2.2'].include?(version)
        validate_server_version
      elsif version && ['0.14', '1.0'].include?(version)
        warn '[CRITICAL] Config version is too old. Try `migrate` instead of `import`.'
        exit 2
      else
        warn '[CRITICAL] Config version is unknown or not supported.'
        exit 3
      end
    end

    def validate_migrate_version(version)
      if version && ['0.14', '1.0', '1.1', '1.2', '1.4', '1.5'].include?(version)
        true
      else
        warn '[CRITICAL] Config version must be 0.14 or 1.0-1.5 for migration.'
        exit 4
      end
    end

    def validate_server_version
      server_version = SkullIsland::APIClient.about_service['version']
      if server_version.match?(/^2.[12]/)
        true
      elsif server_version.match?(/^2.0/)
        warn "[WARN] Older server version #{server_version} detected! " \
             'You may encounter Service resource API exceptions.'
      else
        warn '[CRITICAL] Server version mismatch!'
        exit 1
      end
    end
  end
end
