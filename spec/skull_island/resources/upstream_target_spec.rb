# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::UpstreamTarget do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::UpstreamTarget.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#target-object
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'target' => '1.2.3.4:80',
        'weight' => 15,
        'upstream_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        'created_at' => 1485523507446
      }
    end

    let(:updated_resource_post) do
      {
        'target' => '4.5.6.7:80',
        'weight' => 15,
        'upstream_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432'
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        'target' => '4.5.6.7:80',
        'weight' => 15,
        'upstream_id' => 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        'created_at' => 1485523507446
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{SkullIsland::Resources::Upstream.relative_uri}/ee3310c1-6789-40ac-9386-f79c0cb58432" \
          '/targets/4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        response: existing_resource_raw
      )
      SkullIsland::Resources::UpstreamTarget.get(
        '4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        upstream: 'ee3310c1-6789-40ac-9386-f79c0cb58432',
        api_client: client
      )
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(existing_resource.weight).to eq(15)
    end

    it 'creates new resources' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Upstream.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/targets',
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.weight).to be nil
      resource.target = '4.5.6.7:80'
      resource.weight = 15
      resource.upstream = 'ee3310c1-6789-40ac-9386-f79c0cb58432'
      expect(resource.save).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.weight).to eq(15)
    end

    it 'creates new resources via upstreams' do
      resource = subject
      resource.api_client.response_for(
        :post,
        "#{SkullIsland::Resources::Upstream.relative_uri}/" \
          'ee3310c1-6789-40ac-9386-f79c0cb58432/targets',
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.weight).to be nil
      resource.target = '4.5.6.7:80'
      resource.weight = 15
      upstream = SkullIsland::Resources::Upstream.get(
        'ee3310c1-6789-40ac-9386-f79c0cb58432',
        lazy: true,
        api_client: subject.api_client
      )
      expect(upstream.add_target!(resource)).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.weight).to eq(15)
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :put,
        "#{SkullIsland::Resources::Upstream.relative_uri}/ee3310c1-6789-40ac-9386-f79c0cb58432" \
          '/targets/4661f55e-95c2-4011-8fd6-c5c56df1c9db',
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.target).to eq('1.2.3.4:80')
      resource.target = '4.5.6.7:80'
      expect(resource.save).to be true
      expect(resource.id).to eq('4661f55e-95c2-4011-8fd6-c5c56df1c9db')
      expect(resource.target).to eq('4.5.6.7:80')
    end
  end
end
