# frozen_string_literal: true

require 'spec_helper'

describe AggregationSerializer do
  let(:aggregation) { create(:aggregation) }

  it_behaves_like 'a panoptes restpack serializer' do
    let(:resource) { aggregation }
    let(:includes) { %i[project user workflow] }
    let(:preloads) { [] }
  end
end
