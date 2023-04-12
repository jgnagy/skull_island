# frozen_string_literal: true

RSpec.describe CoreExtensions::String::Transformations do
  subject do
    Foo.new('a_test_string')
  end

  before do
    fake_string_class = Class.new(String) { include CoreExtensions::String::Transformations }
    stub_const('Foo', fake_string_class)
  end

  let(:camel_string) do
    Foo.new('CamelCaseString')
  end

  it 'converts underscored strings to CamelCase' do
    expect(subject.to_camel).to eq('ATestString')
  end

  it 'converts humanizes underscored strings' do
    expect(subject.humanize).to eq('A test string')
  end

  it 'converts CamelCase to underscored strings' do
    expect(camel_string.to_underscore).to eq('camel_case_string')
  end
end
