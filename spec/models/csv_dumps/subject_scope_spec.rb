# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CsvDumps::SubjectScope do
  let(:project) { create(:project) }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1, project: project) }
  let(:scope_cache) { instance_double(SubjectDumpCache) }

  before do
    allow(scope_cache).to receive(:reset_for_batch)
    workflow
  end

  it 'yields subjects' do
    scope = described_class.new(project, scope_cache)
    yielded = []
    scope.each { |s| yielded << s }
    expect(yielded).not_to be_empty
  end

  it 'resets cache per batch' do
    scope = described_class.new(project, scope_cache)
    scope.each { |_s| nil }
    expect(scope_cache).to have_received(:reset_for_batch).at_least(:once)
  end
end
