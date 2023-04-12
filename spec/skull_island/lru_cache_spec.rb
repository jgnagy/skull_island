# frozen_string_literal: true

RSpec.describe SkullIsland::LRUCache do
  let(:populated_cache) do
    cache = described_class.new
    cache.store(:foo, 'bar')
    cache
  end

  let(:larger_cache) do
    described_class.new(500)
  end

  it 'allows retrieving cached items' do
    expect(populated_cache.retrieve(:foo)).to eq('bar')
  end

  it 'allows storing additional items' do
    expect(populated_cache.size).to eq(1)
    populated_cache.store(:this, 'that')
    expect(populated_cache.size).to eq(2)
  end

  it 'provides a simple Array of all cached values' do
    expect(populated_cache.values).to eq(['bar'])
  end

  it 'can be converted to a simple Hash' do
    expect(populated_cache.to_hash).to eq(foo: 'bar')
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

  it 'allows flushing cache (including metadata)' do
    expect(populated_cache.size).to eq(1)
    expect(populated_cache[:foo]).to eq('bar')
    expect(populated_cache[:not_here]).to be_nil
    expect(populated_cache.statistics[:hits]).not_to eq(0)
    expect(populated_cache.statistics[:misses]).not_to eq(0)
    populated_cache.flush
    expect(populated_cache.size).to eq(0)
    expect(populated_cache.statistics[:hits]).to eq(0)
    expect(populated_cache.statistics[:misses]).to eq(0)
  end

  it 'allows creating larger caches than default' do
    expect(larger_cache.max_size).to eq(500)
  end
end
