# frozen_string_literal: true

module SkullIsland
  # Resource classes go here...
  module Resources
    # The CA Certificate resource class
    #
    # @see https://docs.konghq.com/1.4.x/admin-api/#ca-certificate-object CA Certificate definition
    class CACertificate < Resource
      include Helpers::Meta

      property :cert, required: true, validate: true
      property :created_at, read_only: true, postprocess: true
      property :tags, validate: true, preprocess: true, postprocess: true

      def self.batch_import(data, verbose: false, test: false, project: nil, time: nil)
        raise(Exceptions::InvalidArguments) unless data.is_a?(Array)

        known_ids = []

        data.each_with_index do |resource_data, index|
          resource = new
          resource.delayed_set(:cert, resource_data)
          resource.tags = resource_data['tags'] if resource_data['tags']
          resource.project = project if project
          resource.import_time = (time || Time.now.utc.to_i) if project
          resource.import_update_or_skip(index: index, verbose: verbose, test: test)
          known_ids << resource.id
        end

        cleanup_except(project, known_ids) if project
      end

      def export(options = {})
        hash = { 'cert' => cert }
        hash['tags'] = tags unless tags.empty?
        [*options[:exclude]].each do |exclude|
          hash.delete(exclude.to_s)
        end
        [*options[:include]].each do |inc|
          hash[inc.to_s] = send(inc.to_sym)
        end
        hash.reject { |_, value| value.nil? }
      end

      def modified_existing?
        return false unless new?

        # Find CA certs of the same cert
        same_cert = self.class.where(:cert, cert)

        existing = same_cert.size == 1 ? same_cert.first : nil

        if existing
          @entity['id'] = existing.id
          save
        else
          false
        end
      end

      private

      # Used to validate {#cert} on set
      def validate_cert(value)
        # only String is allowed
        value.is_a?(String)
      end
    end
  end
end
