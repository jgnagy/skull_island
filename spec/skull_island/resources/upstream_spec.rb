# frozen_string_literal: true

RSpec.describe SkullIsland::Resources::Upstream do
  describe 'when configured' do
    subject do
      client = FakeAPIClient.new
      SkullIsland::Resources::Upstream.new(api_client: client)
    end

    let(:existing_resource_raw) do
      # Taken straight from https://docs.konghq.com/0.14.x/admin-api/#upstream-objects
      {
        'id' => '13611da7-703f-44f8-b790-fc1e7bf51b3e',
        'name' => 'service.v1.xyz',
        'hash_on' => 'none',
        'hash_fallback' => 'none',
        'healthchecks' => {
          'active' => {
            'concurrency' => 10,
            'healthy' => {
              'http_statuses' => [200, 302],
              'interval' => 0,
              'successes' => 0
            },
            'http_path' => '/',
            'timeout' => 1,
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [
                429, 404, 500, 501, 502, 503, 504, 505
              ],
              'interval' => 0,
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          },
          'passive' => {
            'healthy' => {
              'http_statuses' => [
                200, 201, 202, 203, 204, 205, 206, 207,
                208, 226, 300, 301, 302, 303, 304, 305,
                306, 307, 308
              ],
              'successes' => 0
            },
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [429, 500, 503],
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          }
        },
        'slots' => 10,
        'created_at' => 1485521710265
      }
    end

    let(:updated_resource_post) do
      {
        'name' => 'service.v1.xyz',
        'hash_on' => 'none',
        'hash_fallback' => 'none',
        'healthchecks' => {
          'active' => {
            'concurrency' => 5,
            'healthy' => {
              'http_statuses' => [200, 302],
              'interval' => 0,
              'successes' => 0
            },
            'http_path' => '/',
            'timeout' => 1,
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [
                429, 404, 500, 501, 502, 503, 504, 505
              ],
              'interval' => 0,
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          },
          'passive' => {
            'healthy' => {
              'http_statuses' => [
                200, 201, 202, 203, 204, 205, 206, 207,
                208, 226, 300, 301, 302, 303, 304, 305,
                306, 307, 308
              ],
              'successes' => 0
            },
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [429, 500, 503],
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          }
        },
        'slots' => 10
      }
    end

    let(:updated_resource_raw) do
      {
        'id' => '13611da7-703f-44f8-b790-fc1e7bf51b3e',
        'name' => 'service.v1.xyz',
        'hash_on' => 'none',
        'hash_fallback' => 'none',
        'healthchecks' => {
          'active' => {
            'concurrency' => 5,
            'healthy' => {
              'http_statuses' => [200, 302],
              'interval' => 0,
              'successes' => 0
            },
            'http_path' => '/',
            'timeout' => 1,
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [
                429, 404, 500, 501, 502, 503, 504, 505
              ],
              'interval' => 0,
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          },
          'passive' => {
            'healthy' => {
              'http_statuses' => [
                200, 201, 202, 203, 204, 205, 206, 207,
                208, 226, 300, 301, 302, 303, 304, 305,
                306, 307, 308
              ],
              'successes' => 0
            },
            'unhealthy' => {
              'http_failures' => 0,
              'http_statuses' => [429, 500, 503],
              'tcp_failures' => 0,
              'timeouts' => 0
            }
          }
        },
        'slots' => 10,
        'created_at' => 1485521710265
      }
    end

    let(:existing_resource) do
      client = FakeAPIClient.new
      client.response_for(
        :get,
        "#{subject.class.relative_uri}/13611da7-703f-44f8-b790-fc1e7bf51b3e",
        response: existing_resource_raw
      )
      SkullIsland::Resources::Upstream.get(
        '13611da7-703f-44f8-b790-fc1e7bf51b3e',
        api_client: client
      )
    end

    it 'finds existing resources' do
      expect(existing_resource.id).to eq('13611da7-703f-44f8-b790-fc1e7bf51b3e')
      expect(existing_resource.slots).to eq(10)
      expect(existing_resource.name).to eq('service.v1.xyz')
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
      resource.name = 'service.v1.xyz'
      resource.hash_on = 'none'
      resource.hash_fallback = 'none'
      resource.slots = 10
      resource.healthchecks = {
        'active' => {
          'concurrency' => 5,
          'healthy' => {
            'http_statuses' => [200, 302],
            'interval' => 0,
            'successes' => 0
          },
          'http_path' => '/',
          'timeout' => 1,
          'unhealthy' => {
            'http_failures' => 0,
            'http_statuses' => [
              429, 404, 500, 501, 502, 503, 504, 505
            ],
            'interval' => 0,
            'tcp_failures' => 0,
            'timeouts' => 0
          }
        },
        'passive' => {
          'healthy' => {
            'http_statuses' => [
              200, 201, 202, 203, 204, 205, 206, 207,
              208, 226, 300, 301, 302, 303, 304, 305,
              306, 307, 308
            ],
            'successes' => 0
          },
          'unhealthy' => {
            'http_failures' => 0,
            'http_statuses' => [429, 500, 503],
            'tcp_failures' => 0,
            'timeouts' => 0
          }
        }
      }
      expect(resource.save).to be true
      expect(resource.id).to eq('13611da7-703f-44f8-b790-fc1e7bf51b3e')
      expect(resource.name).to eq('service.v1.xyz')
    end

    it 'allows updating a resource' do
      resource = existing_resource
      resource.api_client.response_for(
        :patch,
        "#{subject.class.relative_uri}/13611da7-703f-44f8-b790-fc1e7bf51b3e",
        data: updated_resource_post,
        response: updated_resource_raw
      )
      expect(resource.healthchecks.dig('active', 'concurrency')).to eq(10)
      resource.healthchecks['active']['concurrency'] = 5
      expect(resource.save).to be true
      expect(resource.id).to eq('13611da7-703f-44f8-b790-fc1e7bf51b3e')
      expect(resource.slots).to eq(10)
      expect(resource.healthchecks.dig('active', 'concurrency')).to eq(5)
      expect(resource.name).to eq('service.v1.xyz')
    end
  end
end
