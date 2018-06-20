require "spec_helper"

RSpec.describe Subjects::SelectorContext do
  let(:project) { create(:project_with_workflow) }
  let(:user) { project.owner }
  let(:workflow) { project.workflows.first }
  let(:api_user) { ApiUser.new(user) }
  let(:subject_ids) { [1,2] }
  let(:expected_context) do
    {
      user_seen_subject_ids: subject_ids,
      favorite_subject_ids: subject_ids - [1],
      retired_subject_ids: subject_ids - [2],
      url_format: :get,
      user_has_finished_workflow: false,
      select_context: true
    }
  end
  subject { described_class.new(api_user, workflow, subject_ids) }

  it 'should return an empty object if skip flag is set' do
    Panoptes.flipper[:skip_subject_selection_context].enable
    expect(subject.format).to eq({})
  end

  context "with seens, favourites and retired data", :focus do
    before do
      create(
        :user_seen_subject,
        user: user,
        workflow: workflow,
        build_real_subjects: false,
        subject_ids: subject_ids
      )
      allow(FavoritesFinder).to receive(:find).and_return([2])
      allow(SubjectWorkflowRetirements).to receive(:find).and_return([1])
    end

    it 'should return the expected format' do
      expect(subject.format).to eq(expected_context)
    end
  end
end
