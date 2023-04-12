# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Plugin do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      described_class.new(api_client: client)
    end

    let(:consumer_raw) do
      {
        'id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4',
        'username' => 'a_consumer'
      }
    end

    let(:service_raw) do
      {
        'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21',
        'name' => 'a_service'
      }
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#plugin-object
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'service' => { 'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21' },
        'consumer' => { 'id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4' },
        'name' => 'rate-limiting',
        'config' => {
          'hour' => 500,
          'minute' => 20
        },
        'enabled' => true,
        'created_at' => 1422386534
      }
    end

    let(:updated_resource_post) do
      {
        'service' => { 'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21' },
        'consumer' => { 'id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4' },
        'name' => 'rate-limiting',
        'config' => {
          'hour' => 1000,
          'minute' => 50
        },
        'enabled' => true
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '4d924084-1adb-40a5-c042-63b19db421d1',
        'service' => { 'id' => '5fd1z584-1adb-40a5-c042-63b19db49x21' },
        'consumer' => { 'id' => 'a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4' },
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
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Consumer.relative_uri}" \
        '/a3dX2dh2-1adb-40a5-c042-63b19dbx83hF4',
        response: consumer_raw
      )
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Service.relative_uri}" \
        '/5fd1z584-1adb-40a5-c042-63b19db49x21',
        response: service_raw
      )
      described_class.get(
        '4d924084-1adb-40a5-c042-63b19db421d1',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'service' => "<%= lookup :service, 'a_service' %>",
        'consumer' => "<%= lookup :consumer, 'a_consumer' %>",
        'name' => 'rate-limiting',
        'config' => {
          'hour' => 500,
          'minute' => 20
        },
        'enabled' => true
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'enabled' }
    end

    let(:exported_resource_inclusions) do
      r = 'plugins/4d924084-1adb-40a5-c042-63b19db421d1'
      exported_resource.merge('relative_uri' => r)
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
      expect(resource.name).to be_nil
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
        :patch,
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

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :enabled)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
