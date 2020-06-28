# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvDumps::DumpProcessor do
  let(:formatter) { double("Formatter", headers: false).tap { |f| allow(f).to receive(:to_rows) { |model| [model] } } }
  let(:scope) { [] }
  let(:medium) { double("Medium", put_file: true, metadata: {}, save!: true) }
  let(:csv_dump) { double(CsvDump, cleanup!: true, gzip!: true) }
  let(:processor) { described_class.new(formatter, scope, medium, csv_dump) }

  let(:project_file_name) do
    "#{dump_type}_#{project.owner.login}_#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  it_behaves_like 'a dump processor'

  it 'creates a csv file with the correct number of entries' do
    allow(csv_dump).to receive(:<<)
    scope << 1
    scope << 2
    processor.execute
    expect(csv_dump).to have_received(:<<).twice
  end
end
