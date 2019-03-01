# frozen_string_literal: true

RSpec.describe SkullIsland::LRUCache do
  let(:populated_cache) do
    cache = SkullIsland::LRUCache.new
    cache.store(:foo, 'bar')
    cache
  end

  let(:larger_cache) do
    SkullIsland::LRUCache.new(500)
  end

  it 'allows retrieving cached items' do
    expect(populated_cache.retrieve(:foo)).to eq('bar')
  end

  it 'allows invalidating cached items' do
    populated_cache.invalidate(:foo)
    expect(populated_cache.retrieve(:foo)).not_to eq('bar')
  end

  it 'allows truncating cache' do
    expect(populated_cache.size).to eq(1)
    populated_cache.truncate
    expect(populated_cache.size).to eq(0)
  end

  it 'allows creating larger caches than default' do
    expect(larger_cache.max_size).to eq(500)
  end
end
