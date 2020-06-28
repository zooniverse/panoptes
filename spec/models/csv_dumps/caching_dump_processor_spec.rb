# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvDumps::CachingDumpProcessor do
  let(:formatter) do
    formatter = double('Formatter', headers: [], attribute: 1)
    allow(formatter).to receive(:model=)
    formatter
  end
  let(:scope) { [] }
  let(:medium) { double("Medium", put_file: true, metadata: {}, save!: true) }
  let(:csv_dump) { double(CsvDump, cleanup!: true, gzip!: true, '<<': true) }
  let(:my_proc) { proc {} }
  let(:processor) do
    described_class.new(formatter, scope, medium, csv_dump, &my_proc)
  end
  let(:cached_export) { instance_double('CachedExport', data: {}) }

  let(:project_file_name) do
    "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  it_behaves_like 'a dump processor'

  it 'creates a csv file with the correct number of entries' do
    allow(csv_dump).to receive(:<<)
    scope << double(cached_export: cached_export) # rubocop:disable RSpec/VerifiedDoubles
    scope << double(cached_export: cached_export) # rubocop:disable RSpec/VerifiedDoubles
    processor.execute
    expect(csv_dump).to have_received(:<<).exactly(2).times
  end

  it 'stores the yield block for later use' do
    expect(processor.yield_block).to eq(my_proc)
  end

  describe '#perform_dump' do
    let(:scope) { [Classification.new] }

    # TODO: spec out using the Formatter::Caching
    # and how we export using this intead of normal

    it 'calls the stored yield block with a caching formatter' do
      allow(my_proc).to receive(:call).once
      processor.perform_dump
      expect(my_proc).to have_received(:call).with(
        instance_of(Formatter::Caching)
      )
    end
  end
end
