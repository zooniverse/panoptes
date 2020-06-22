# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvDumps::CachingDumpProcessor, focus: true do
  let(:formatter) { double("Formatter", headers: false).tap { |f| allow(f).to receive(:to_rows) { |model| [model] } } }
  let(:scope) { [] }
  let(:medium) { double("Medium", put_file: true, metadata: {}, save!: true) }
  let(:csv_dump) { double(CsvDump, cleanup!: true, gzip!: true, '<<': true) }
  let(:processor) { described_class.new(formatter, scope, medium, csv_dump) }

  let(:project_file_name) do
    "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  it_behaves_like 'a dump processor'

  # rubocop:disable RSpec/MultipleExpectations
  it 'passes the provided block to perform_dump' do
    my_proc = proc { }
    expect(processor).to receive(:execute) do |&block|
      expect(block).to be(my_proc)
    end
    processor.execute(&my_proc)
  end
  # rubocop:enable RSpec/MultipleExpectations

  describe '#perform_dump' do
    let(:scope) { [Classification.new] }

    it 'yields with the formatter if a block is passed' do
      expect { |b| processor.perform_dump(&b) }.to yield_with_args
    end
  end
end
