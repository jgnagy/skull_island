# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::AccessControlList do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::AccessControlList.new(api_client: client)
    end

    let(:consumer_raw) do
      {
        'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        'username' => 'my_consumer'
      }
    end

    let(:existing_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'group' => 'testgroup',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' },
        'created_at' => 1485523507446
      }
    end

    let(:new_resource_post) do
      {
        'group' => 'othergroup',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' }
      }
    end

    let(:new_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'group' => 'othergroup',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' },
        'created_at' => 1485523507446
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{SkullIsland::Resources::AccessControlList.relative_uri}" \
          '/4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        response: existing_resource_raw
      )
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Consumer.relative_uri}" \
          '/ee3310c1-6789-40ac-9386-f79c0cb58432',
        response: consumer_raw
      )
      SkullIsland::Resources::AccessControlList.get(
        '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'group' => 'testgroup',
        'consumer' => "<%= lookup :consumer, 'my_consumer' %>"
      }
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(existing_resource.group).to eq('testgroup')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/acls',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.group).to be nil
      resource.group = 'othergroup'
      resource.consumer = { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' }
      expect(resource.save).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.group).to eq('othergroup')
    end

    it 'creates new resources via consumers' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/acls',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.group).to be nil
      resource.group = 'othergroup'
      consumer = SkullIsland::Resources::Consumer.get(
        'ee3310c1-6789-40ac-9386-f79c0cb58432',
        lazy: true,
        api_client: subject.api_client
      )
      expect(consumer.add_acl!(resource)).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.group).to eq('othergroup')
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end
  end
end
