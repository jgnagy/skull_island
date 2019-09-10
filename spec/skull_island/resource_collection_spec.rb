# frozen_string_literal: true

RSpec.describe SkullIsland::ResourceCollection do
  subject do
    client = FakeAPIClient.new
    SkullIsland::ResourceCollection.new([1, 2, 3], api_client: client)
  end

  let(:empty_collection) do
    client = FakeAPIClient.new
    SkullIsland::ResourceCollection.new([], type: Integer, api_client: client)
  end

  let(:other_collection) do
    client = FakeAPIClient.new
    SkullIsland::ResourceCollection.new([5, 3, 4], api_client: client)
  end

  it 'reports when it is empty' do
    expect(subject.empty?).to be(false)
    expect(empty_collection.empty?).to be(true)
  end

  it 'can provide the first object' do
    expect(subject.first).to eq(1)
  end

  it 'can provide the first n objects' do
    expect(subject.first(2)).to be_a(subject.class)
    expect(subject.first(2).to_a).to eq([1, 2])
  end

  it 'can provide the last object' do
    expect(subject.last).to eq(3)
  end

  it 'can provide the last n objects' do
    expect(subject.last(2)).to be_a(subject.class)
    expect(subject.last(2).to_a).to eq([2, 3])
  end

  it 'supports merging like collections' do
    expect(subject.merge(other_collection)).to be_a(subject.class)
    expect(subject.merge(other_collection).to_a).to eq([1, 2, 3, 5, 4])
  end

  it 'supports querying its model type' do
    expect(subject.model).to be(Integer)
    expect(subject.type).to be(Integer)
  end

  it 'supports pagination' do
    expect(subject.paginate(per_page: 1, page: 1)).to eq([1])
    expect(subject.paginate(per_page: 1, page: 2)).to eq([2])
    expect(subject.paginate(per_page: 2, page: 1)).to eq([1, 2])
  end

  it 'reports its size' do
    expect(subject.size).to eq(3)
  end

  it 'supports sorting' do
    expect(other_collection.sort.to_a).to eq([3, 4, 5])
    expect(subject.sort { |a, b| b <=> a }.to_a).to eq([3, 2, 1])
  end

  it 'can return specific results' do
    expect(subject[1]).to eq(2)
    expect(subject[0..1]).to be_a(subject.class)
    expect(subject[0..1].to_a).to eq([1, 2])
  end

  it 'supports an "add" operation' do
    expect(subject + other_collection).to be_a(subject.class)
    expect((subject + other_collection).to_a).to eq([1, 2, 3, 5, 3, 4])
  end

  it 'supports a "subtract" operation' do
    expect(subject - other_collection).to be_a(subject.class)
    expect((subject - other_collection).to_a).to eq([1, 2])
  end
end
