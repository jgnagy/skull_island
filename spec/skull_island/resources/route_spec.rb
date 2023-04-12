# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Route do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      described_class.new(api_client: client)
    end

    let(:service_raw) do
      {
        'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2',
        'name' => 'a_service'
      }
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#route-object
      {
        'id' => '22108377-8f26-4c0e-bd9e-2962c1d6b0e6',
        'created_at' => 14888869056483,
        'updated_at' => 14888869056483,
        'protocols' => %w[http https],
        'methods' => nil,
        'hosts' => ['example.com'],
        'paths' => nil,
        'regex_priority' => 0,
        'strip_path' => true,
        'preserve_host' => false,
        'service' => {
          'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2'
        }
      }
    end

    let(:updated_resource_post) do
      {
        'protocols' => %w[http https],
        'hosts' => ['example.com', 'example.org'],
        'regex_priority' => 0,
        'strip_path' => true,
        'preserve_host' => false,
        'service' => {
          'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2'
        }
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '22108377-8f26-4c0e-bd9e-2962c1d6b0e6',
        'created_at' => 14888869056483,
        'updated_at' => 14888869056499,
        'protocols' => %w[http https],
        'methods' => nil,
        'hosts' => ['example.com', 'example.org'],
        'paths' => nil,
        'regex_priority' => 0,
        'strip_path' => true,
        'preserve_host' => false,
        'service' => {
          'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2'
        }
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/22108377-8f26-4c0e-bd9e-2962c1d6b0e6",
        response: existing_resource_raw
      )
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Service.relative_uri}/4e13f54a-bbf1-47a8-8777-255fed7116f2",
        response: service_raw
      )
      described_class.get(
        '22108377-8f26-4c0e-bd9e-2962c1d6b0e6',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'protocols' => %w[http https],
        'hosts' => ['example.com'],
        'regex_priority' => 0,
        'strip_path' => true,
        'preserve_host' => false,
        'service' => "<%= lookup :service, 'a_service' %>"
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'regex_priority' }
    end

    let(:exported_resource_inclusions) do
      r = 'routes/22108377-8f26-4c0e-bd9e-2962c1d6b0e6'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('22108377-8f26-4c0e-bd9e-2962c1d6b0e6')
      expect(existing_resource.hosts).to eq(['example.com'])
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.hosts).to be_nil
      resource.hosts = ['example.com', 'example.org']
      resource.protocols = %w[http https]
      resource.regex_priority = 0
      resource.strip_path = true
      resource.preserve_host = false
      resource.service = { 'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2' }
      expect(resource.save).to be true
      expect(resource.id).to eq('22108377-8f26-4c0e-bd9e-2962c1d6b0e6')
      expect(resource.hosts).to eq(['example.com', 'example.org'])
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/22108377-8f26-4c0e-bd9e-2962c1d6b0e6",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.updated_at).to eq(Time.at(14888869056483).utc.to_datetime)
      expect(resource.hosts).to eq(['example.com'])
      resource.hosts = ['example.com', 'example.org']
      expect(resource.save).to be true
      expect(resource.id).to eq('22108377-8f26-4c0e-bd9e-2962c1d6b0e6')
      expect(resource.hosts).to eq(['example.com', 'example.org'])
      expect(resource.updated_at).to eq(Time.at(14888869056499).utc.to_datetime)
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :regex_priority)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
