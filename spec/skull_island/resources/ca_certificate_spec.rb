# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::CACertificate do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      described_class.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/1.4.x/admin-api/#retrieve-ca-certificate
      {
        'id' => '04fbeacf-a9f1-4a5d-ae4a-b0407445db3f',
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'created_at' => 1485521710265,
        'tags' => %w[user-level low-priority]
      }
    end

    let(:updated_resource_post) do
      {
        'cert' => '-----BEGIN CERTIFICATE-----...;-P',
        'tags' => %w[user-level low-priority]
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '04fbeacf-a9f1-4a5d-ae4a-b0407445db3f',
        'cert' => '-----BEGIN CERTIFICATE-----...;-P',
        'created_at' => 1485521710265,
        'tags' => %w[user-level low-priority]
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/04fbeacf-a9f1-4a5d-ae4a-b0407445db3f",
        response: existing_resource_raw
      )
      described_class.get(
        '04fbeacf-a9f1-4a5d-ae4a-b0407445db3f',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'cert' => '-----BEGIN CERTIFICATE-----...',
        'tags' => %w[user-level low-priority]
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'tags' }
    end

    let(:exported_resource_inclusions) do
      r = 'ca_certificates/04fbeacf-a9f1-4a5d-ae4a-b0407445db3f'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('04fbeacf-a9f1-4a5d-ae4a-b0407445db3f')
      expect(existing_resource.tags).to eq(%w[user-level low-priority])
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.tags).to be_empty
      resource.cert = '-----BEGIN CERTIFICATE-----...;-P'
      resource.tags = %w[user-level low-priority]
      expect(resource.save).to be true
      expect(resource.id).to eq('04fbeacf-a9f1-4a5d-ae4a-b0407445db3f')
      expect(resource.tags).to eq(%w[user-level low-priority])
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/04fbeacf-a9f1-4a5d-ae4a-b0407445db3f",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.cert).to eq('-----BEGIN CERTIFICATE-----...')
      resource.cert = "#{resource.cert};-P"
      expect(resource.save).to be true
      expect(resource.id).to eq('04fbeacf-a9f1-4a5d-ae4a-b0407445db3f')
      expect(resource.cert).to eq('-----BEGIN CERTIFICATE-----...;-P')
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :tags)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
