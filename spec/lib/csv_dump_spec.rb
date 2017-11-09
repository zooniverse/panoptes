require 'spec_helper'

describe CsvDump do
  it 'constructs a csv file' do
    csv_dump = CsvDump.new
    csv_dump << [1, 2, 3]
    csv_dump << [4, 5, 6]

    contents = csv_dump.reopen { |file| file.read }
    expect(contents).to eq("1,2,3\n4,5,6\n")
  end
end
