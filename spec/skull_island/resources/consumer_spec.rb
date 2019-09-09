# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Consumer do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::Consumer.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#retrieve-consumer
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'custom_id' => 'abc123',
        'created_at' => 1422386534
      }
    end

    let(:updated_resource_post) do
      {
        'custom_id' => 'def456'
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'custom_id' => 'def456',
        'created_at' => 1422386534
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/4d924084-1adb-40a5-c042-63b19db421d1",
        response: existing_resource_raw
      )
      SkullIsland::Resources::Consumer.get(
        '4d924084-1adb-40a5-c042-63b19db421d1',
        api_client: client
      )
    end

    let(:empty_creds_hash) do
      {
        'key-auth' => [],
        'basic-auth' => [],
        'jwt' => []
      }
    end

    let(:exported_resource) do
      {
        'custom_id' => 'abc123'
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'custom_id' }
    end

    let(:exported_resource_inclusions) do
      r = 'consumers/4d924084-1adb-40a5-c042-63b19db421d1'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(existing_resource.custom_id).to eq('abc123')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.custom_id).to be nil
      resource.custom_id = 'def456'
      expect(resource.save).to be true
      expect(resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(resource.custom_id).to eq('def456')
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/4d924084-1adb-40a5-c042-63b19db421d1",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.custom_id).to eq('abc123')
      resource.custom_id = 'def456'
      expect(resource.save).to be true
      expect(resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(resource.custom_id).to eq('def456')
    end

    it 'supports exporting resources' do
      allow(existing_resource).to receive(:credentials).and_return(empty_creds_hash)
      allow(existing_resource).to receive(:acls).and_return([])
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      allow(existing_resource).to receive(:credentials).and_return(empty_creds_hash)
      allow(existing_resource).to receive(:acls).and_return([])
      expect(existing_resource.export(exclude: :custom_id)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      allow(existing_resource).to receive(:credentials).and_return(empty_creds_hash)
      allow(existing_resource).to receive(:acls).and_return([])
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
