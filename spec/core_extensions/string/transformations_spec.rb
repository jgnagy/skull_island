# frozen_string_literal: true

RSpec.describe CoreExtensions::String::Transformations do
  subject do
    class Foo < String
      include CoreExtensions::String::Transformations
    end

    Foo.new('a_test_string')
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
