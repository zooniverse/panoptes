# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvDumps::YieldingDumpProcessor do
  let(:formatter) { double("Formatter", headers: false).tap { |f| allow(f).to receive(:to_rows) { |model| [model] } } }
  let(:scope) { [] }
  let(:medium) { double("Medium", put_file: true, metadata: {}, save!: true) }
  let(:csv_dump) { double(CsvDump, cleanup!: true, gzip!: true, '<<': true) }
  let(:my_proc) { proc {} }
  let(:processor) do
    described_class.new(formatter, scope, medium, csv_dump, &my_proc)
  end

  let(:project_file_name) do
    "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  it_behaves_like 'a dump processor'

  it 'stores the yield block for later use' do
    expect(processor.yield_block).to eq(my_proc)
  end

  describe '#perform_dump' do
    let(:scope) { [Classification.new] }

    it 'calls the yield stored block with the formatter' do
      allow(my_proc).to receive(:call).once
      processor.perform_dump
      expect(my_proc).to have_received(:call).with(formatter)
    end
  end
end
