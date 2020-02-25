# frozen_string_literal: true

RSpec.describe CoreExtensions::Hash::Pruning do
  subject do
    class Bar < Hash
      include CoreExtensions::Hash::Pruning
    end

    bar = Bar.new
    bar[:a] = ''
    bar[:b] = nil
    bar[:c] = 0
    bar[:d] = {}
    bar[:e] = 'keep me'
    bar
  end

  it 'removes empty and nil values' do
    expect(subject.prune).to eq(c: 0, e: 'keep me')
  end
end
