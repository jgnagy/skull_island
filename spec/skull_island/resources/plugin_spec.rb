# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Plugin do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::Plugin.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#plugin-object
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'service_id' => '5fd1z584-1adb-40a5-c042-63b19db49x21',
        'consumer_id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4',
        'name' => 'rate-limiting',
        'config' => {
          'minute' => 20,
          'hour' => 500
        },
        'enabled' => true,
        'created_at' => 1422386534
      }
    end

    let(:updated_resource_post) do
      {
        'service_id' => '5fd1z584-1adb-40a5-c042-63b19db49x21',
        'consumer_id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4',
        'name' => 'rate-limiting',
        'config' => {
          'minute' => 50,
          'hour' => 1000
        },
        'enabled' => true
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'service_id' => '5fd1z584-1adb-40a5-c042-63b19db49x21',
        'consumer_id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4',
        'name' => 'rate-limiting',
        'config' => {
          'minute' => 50,
          'hour' => 1000
        },
        'enabled' => true,
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
      SkullIsland::Resources::Plugin.get(
        '4d924084-1adb-40a5-c042-63b19db421d1',
        api_client: client
      )
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(existing_resource.name).to eq('rate-limiting')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        subject.class.relative_uri,
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.name).to be nil
      resource.name = 'rate-limiting'
      resource.service = { 'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21' }
      resource.consumer = { 'id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4' }
      resource.enabled = true
      resource.config = { 'minute' => 50, 'hour' => 1000 }
      expect(resource.save).to be true
      expect(resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(resource.name).to eq('rate-limiting')
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :put,
        "#{subject.class.relative_uri}/4d924084-1adb-40a5-c042-63b19db421d1",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.config).to eq('minute' => 20, 'hour' => 500)
      resource.config = { 'minute' => 50, 'hour' => 1000 }
      expect(resource.save).to be true
      expect(resource.id).to eq('4d924084-1adb-40a5-c042-63b19db421d1')
      expect(resource.config).to eq('minute' => 50, 'hour' => 1000)
    end
  end
end
