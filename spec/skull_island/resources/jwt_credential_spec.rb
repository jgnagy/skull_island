# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::JWTCredential do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::JWTCredential.new(api_client: client)
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
        'algorithm' => 'RS256',
        'key' => '1a2b3c4d5e6f',
        'rsa_public_key' => '-----BEGIN CERTIFICATE-----...',
        'secret' => '0zcfJRuzmnONGxtMUaR53E4xagooqh3y',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' },
        'created_at' => 1485523507446
      }
    end

    let(:new_resource_post) do
      {
        'algorithm' => 'RS256',
        'key' => '2b3c4d5e6f7a',
        'rsa_public_key' => '-----BEGIN CERTIFICATE-----...',
        'secret' => '0ecfJRuzmnONGxtMUaR53E4xagooqh3y',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' }
      }
    end

    let(:new_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'algorithm' => 'RS256',
        'key' => '2b3c4d5e6f7a',
        'rsa_public_key' => '-----BEGIN CERTIFICATE-----...',
        'secret' => '0ecfJRuzmnONGxtMUaR53E4xagooqh3y',
        'consumer' => { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' },
        'created_at' => 1485523507446
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{SkullIsland::Resources::JWTCredential.relative_uri}" \
        '/4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        response: existing_resource_raw
      )
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Consumer.relative_uri}" \
        '/ee3310c1-6789-40ac-9386-f79c0cb58432',
        response: consumer_raw
      )
      SkullIsland::Resources::JWTCredential.get(
        '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        api_client: client
      )
    end

    let(:exported_resource) do
      {
        'algorithm' => 'RS256',
        'key' => '1a2b3c4d5e6f',
        'rsa_public_key' => '-----BEGIN CERTIFICATE-----...',
        'secret' => '0zcfJRuzmnONGxtMUaR53E4xagooqh3y',
        'consumer' => "<%= lookup :consumer, 'my_consumer' %>"
      }
    end

    let(:exported_resource_exclusions) do
      exported_resource.reject { |k| k == 'consumer' }
    end

    let(:exported_resource_inclusions) do
      r = 'consumers/ee3310c1-6789-40ac-9386-f79c0cb58432' \
          '/jwt/4661f55e-95c2-4011-8fd6-c5c56df1c9db'
      exported_resource.merge('relative_uri' => r)
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(existing_resource.key).to eq('1a2b3c4d5e6f')
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
        'ee3310c1-6789-40ac-9386-f79c0cb58432/jwt',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.key).to be nil
      resource.algorithm = 'RS256'
      resource.key = '2b3c4d5e6f7a'
      resource.rsa_public_key = '-----BEGIN CERTIFICATE-----...'
      resource.secret = '0ecfJRuzmnONGxtMUaR53E4xagooqh3y'
      resource.consumer = { 'id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432' }
      expect(resource.save).to be true

      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.key).to eq('2b3c4d5e6f7a')
    end

    it 'creates new resources via consumers' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Consumer.relative_uri}/" \
        'ee3310c1-6789-40ac-9386-f79c0cb58432/jwt',
        data: new_resource_post,
        response: new_resource_raw
      )
      expect(resource.key).to be nil
      resource.algorithm = 'RS256'
      resource.key = '2b3c4d5e6f7a'
      resource.rsa_public_key = '-----BEGIN CERTIFICATE-----...'
      resource.secret = '0ecfJRuzmnONGxtMUaR53E4xagooqh3y'
      consumer = SkullIsland::Resources::Consumer.get(
        'ee3310c1-6789-40ac-9386-f79c0cb58432',
        lazy: true,
        api_client: subject.api_client
      )
      expect(consumer.add_credential!(resource)).to be true

      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.key).to eq('2b3c4d5e6f7a')
    end

    it 'supports exporting resources' do
      expect(existing_resource.export).to eq(exported_resource)
    end

    it 'supports exporting resources with exclusions' do
      expect(existing_resource.export(exclude: :consumer)).to eq(exported_resource_exclusions)
    end

    it 'supports exporting resources with inclusions' do
      expect(existing_resource.export(include: :relative_uri)).to eq(exported_resource_inclusions)
    end
  end
end
