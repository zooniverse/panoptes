require 'spec_helper'

describe Projects::CreateAggregationsExport do
  let(:user) { create :user }
  let(:api_user) { ApiUser.new(user) }
  let(:operation) { described_class.with(api_user: api_user) }
  let(:resource) { create(:full_project, owner: user) }

  let(:export_worker) { AggregationsDumpWorker }
  let(:medium_type) { "project_aggregations_export" }
  let(:content_type) { "application/x-gzip" }

  it_behaves_like "creates an export"
end
