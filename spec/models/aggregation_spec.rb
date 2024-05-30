# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Aggregation, type: :model do
  let(:aggregation) { build(:aggregation) }

  it 'has a valid factory' do
    expect(aggregation).to be_valid
  end

  it 'is not be valid without a workflow' do
    expect(build(:aggregation, workflow: nil)).not_to be_valid
  end

  it 'is not be valid without a project' do
    expect(build(:aggregation, project: nil)).not_to be_valid
  end

  it 'is not be valid without a user' do
    expect(build(:aggregation, user: nil)).not_to be_valid
  end

  context 'when there is a duplicate workflow_id' do
    before { aggregation.save }

    let(:duplicate) do
      build(:aggregation, workflow: aggregation.workflow, user: aggregation.user)
    end

    it 'is not be valid' do
      expect(duplicate).not_to be_valid
    end

    it 'has the correct error message' do
      duplicate.valid?
      expect(duplicate.errors.full_messages.first).to include('has already been taken')
    end

    it 'raises a uniq index db error' do
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
