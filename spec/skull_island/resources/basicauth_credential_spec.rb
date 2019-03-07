# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::BasicauthCredential do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::BasicauthCredential.new(api_client: client)
    end

    let(:existing_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'username' => 'test',
        'password' => '123451234512345',
        'consumer_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        'created_at' => 1485523507446
      }
    end

    let(:new_resource_post) do
      {
        'username' => 'test2',
        'password' => '234562345623456',
        'consumer_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432'
      }
    end

    let(:new_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'username' => 'test2',
        'password' => '234562345623456',
        'consumer_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        'created_at' => 1485523507446
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{SkullIsland::Resources::BasicauthCredential.relative_uri}" \
          '/4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        response: existing_resource_raw
      )
      SkullIsland::Resources::BasicauthCredential.get(
        '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        api_client: client
      )
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(existing_resource.password).to eq('123451234512345')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/basic-auth',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.password).to be nil
      resource.username = 'test2'
      resource.password = '234562345623456'
      resource.consumer = 'ee3310c1-6789-40ac-9386-f79c0cb58432'
      expect(resource.save).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.password).to eq('234562345623456')
    end

    it 'creates new resources via upstreams' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/basic-auth',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.password).to be nil
      resource.username = 'test2'
      resource.password = '234562345623456'
      consumer = SkullIsland::Resources::Consumer.get(
        'ee3310c1-6789-40ac-9386-f79c0cb58432',
        lazy: true,
        api_client: subject.api_client
      )
      expect(consumer.add_credential!(resource)).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.password).to eq('234562345623456')
    end
  end
end
