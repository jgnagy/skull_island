# frozen_string_literal: true

RSpec.describe CoreExtensions::Hash::Pruning do
  subject do
    bar = Bar.new
    bar[:a] = ''
    bar[:b] = nil
    bar[:c] = 0
    bar[:d] = {}
    bar[:e] = 'keep me'
    bar
  end

  before do
    fake_hash_class = Class.new(Hash) { include CoreExtensions::Hash::Pruning }
    stub_const('Bar', fake_hash_class)
  end

  it 'removes empty and nil values' do
    expect(subject.prune).to eq(c: 0, e: 'keep me')
  end
end
