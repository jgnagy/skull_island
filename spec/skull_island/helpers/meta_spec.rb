# frozen_string_literal: true

RSpec.describe SkullIsland::Helpers::Meta do
  subject do
    class MetaTest
      include SkullIsland::Helpers::Meta

      def initialize(tags)
        @entity = {}
        @entity['tags'] = tags
      end

      def raw_set(key, value)
        @entity[key.to_s] = value
      end
    end

    MetaTest.new(['testtag', '_meta~this~that', '_meta~project~testproj'])
  end

  it 'checks if an objects supports meta' do
    expect(subject.supports_meta?).to be(true)
  end

  it 'provides a hash of metadata tag data' do
    expect(subject.metatags).to be_a(Hash)
    expect(subject.metatags.keys).to include('this')
    expect(subject.metatags['this']).to eq('that')
  end

  it 'records import time' do
    current_time = Time.now
    expect(subject.raw_tags.size).to eq(3)
    subject.import_time = current_time
    expect(subject.import_time).to eq(current_time.to_s)
    expect(subject.raw_tags.size).to eq(4)
  end

  it 'removes metadata' do
    expect(subject.raw_tags).to include('_meta~this~that')
    subject.remove_meta('this')
    expect(subject.raw_tags).not_to include('_meta~this~that')
  end

  it "supports querying an object's project" do
    expect(subject.project).to eq('testproj')
  end

  it "can change an object's project" do
    expect(subject.project).to eq('testproj')
    subject.project = 'otherproject'
    expect(subject.project).to eq('otherproject')
  end
end
