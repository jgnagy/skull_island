# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Certificate do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::Certificate.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#retrieve-certificate
      {
        'id' => '21b69eab-09d9-40f9-a55e-c4ee47fada68',
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'key' => '-----BEGIN RSA PRIVATE KEY-----...',
        'snis' => [
          'example.com'
        ],
        'created_at' => 1485521710265
      }
    end

    let(:updated_resource_post) do
      {
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'key' => '-----BEGIN RSA PRIVATE KEY-----...',
        'snis' => [
          'example.com',
          'example.org'
        ]
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '21b69eab-09d9-40f9-a55e-c4ee47fada68',
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'key' => '-----BEGIN RSA PRIVATE KEY-----...',
        'snis' => [
          'example.com',
          'example.org'
        ],
        'created_at' => 1485521710265
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/21b69eab-09d9-40f9-a55e-c4ee47fada68",
        response: existing_resource_raw
      )
      SkullIsland::Resources::Certificate.get(
        '21b69eab-09d9-40f9-a55e-c4ee47fada68',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'key' => '-----BEGIN RSA PRIVATE KEY-----...',
        'snis' => [
          'example.com'
        ]
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'snis' }
    end

    let(:exported_resource_inclusions) do
      r = 'certificates/21b69eab-09d9-40f9-a55e-c4ee47fada68'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('21b69eab-09d9-40f9-a55e-c4ee47fada68')
      expect(existing_resource.snis).to eq(['example.com'])
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.snis).to be nil
      resource.cert = '-----BEGIN CERTIFICATE-----...'
      resource.key = '-----BEGIN RSA PRIVATE KEY-----...'
      resource.snis = ['example.com', 'example.org']
      expect(resource.save).to be true
      expect(resource.id).to eq('21b69eab-09d9-40f9-a55e-c4ee47fada68')
      expect(resource.snis).to eq(['example.com', 'example.org'])
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/21b69eab-09d9-40f9-a55e-c4ee47fada68",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.snis).to eq(['example.com'])
      resource.snis = resource.snis + ['example.org']
      expect(resource.save).to be true
      expect(resource.id).to eq('21b69eab-09d9-40f9-a55e-c4ee47fada68')
      expect(resource.snis).to eq(['example.com', 'example.org'])
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :snis)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
