# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Service do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::Service.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#service-object
      {
        'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2',
        'created_at' => 1488869076800,
        'updated_at' => 1488869076800,
        'connect_timeout' => 60000,
        'protocol' => 'http',
        'host' => 'example.org',
        'port' => 80,
        'path' => '/api',
        'name' => 'example-service',
        'retries' => 5,
        'read_timeout' => 60000,
        'write_timeout' => 60000,
        'tls_verify' => false
      }
    end

    let(:updated_resource_post) do
      {
        'connect_timeout' => 60000,
        'protocol' => 'http',
        'host' => 'example.com',
        'port' => 80,
        'path' => '/api',
        'name' => 'example-service',
        'retries' => 10,
        'read_timeout' => 60000,
        'write_timeout' => 60000,
        'tls_verify' => false
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '4e13f54a-bbf1-47a8-8777-255fed7116f2',
        'created_at' => 1488869076800,
        'updated_at' => 1488869076830,
        'connect_timeout' => 60000,
        'protocol' => 'http',
        'host' => 'example.com',
        'port' => 80,
        'path' => '/api',
        'name' => 'example-service',
        'retries' => 10,
        'read_timeout' => 60000,
        'write_timeout' => 60000,
        'tls_verify' => false
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/4e13f54a-bbf1-47a8-8777-255fed7116f2",
        response: existing_resource_raw
      )
      client.response_for(
        :get,
        SkullIsland::Resources::Route.relative_uri,
        response: { 'data' => [] }
      )
      SkullIsland::Resources::Service.get(
        '4e13f54a-bbf1-47a8-8777-255fed7116f2',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'connect_timeout' => 60000,
        'protocol' => 'http',
        'host' => 'example.org',
        'port' => 80,
        'path' => '/api',
        'name' => 'example-service',
        'retries' => 5,
        'routes' => [],
        'read_timeout' => 60000,
        'write_timeout' => 60000,
        'tls_verify' => false
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'name' }
    end

    let(:exported_resource_inclusions) do
      r = 'services/4e13f54a-bbf1-47a8-8777-255fed7116f2'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4e13f54a-bbf1-47a8-8777-255fed7116f2')
      expect(existing_resource.protocol).to eq('http')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.protocol).to be nil
      resource.protocol = 'http'
      resource.connect_timeout = 60000
      resource.host = 'example.com'
      resource.port = 80
      resource.path = '/api'
      resource.name = 'example-service'
      resource.retries = 10
      resource.tls_verify = false
      resource.read_timeout = 60000
      resource.write_timeout = 60000
      expect(resource.save).to be true
      expect(resource.id).to eq('4e13f54a-bbf1-47a8-8777-255fed7116f2')
      expect(resource.protocol).to eq('http')
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/4e13f54a-bbf1-47a8-8777-255fed7116f2",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.host).to eq('example.org')
      resource.host = 'example.com'
      resource.retries = 10
      expect(resource.save).to be true
      expect(resource.id).to eq('4e13f54a-bbf1-47a8-8777-255fed7116f2')
      expect(resource.host).to eq('example.com')
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :name)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
