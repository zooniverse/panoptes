require "spec_helper"

RSpec.describe Subjects::SelectorContext do
  let(:project) { create(:project_with_workflow) }
  let(:user) { project.owner }
  let(:workflow) { project.workflows.first }
  let(:api_user) { ApiUser.new(user) }
  let(:subject_ids) { [1,2] }
  let(:expected_context) do
    {
      user_seen_subject_ids: [1],
      favorite_subject_ids: [2],
      retired_subject_ids: [1],
      user_has_finished_workflow: false,
      finished_workflow: false,
      selection_state: :normal,
      url_format: :get,
      select_context: true
    }
  end
  let(:selector) do
    selector = instance_double("Subjects::Selector")
    allow(selector).to receive(:user).and_return(user)
    allow(selector).to receive(:workflow).and_return(workflow)
    allow(selector).to receive(:selection_state).and_return(:normal)
    selector
  end

  subject { described_class.new(selector, subject_ids) }

  it 'should return an empty object if skip flag is set' do
    Panoptes.flipper[:skip_subject_selection_context].enable
    expect(subject.format).to eq({})
  end

  context "with seens, favourites and retired data" do
    before do
      create(
        :user_seen_subject,
        user: user,
        workflow: workflow,
        build_real_subjects: false,
        subject_ids: [1]
      )
      allow(FavoritesFinder).to receive(:find).and_return([2])
      allow(SubjectWorkflowRetirements).to receive(:find).and_return([1])
    end

    it 'should return the expected format' do
      expect(subject.format).to eq(expected_context)
    end
  end

  context "with retired and seen data but external selector returns stale data" do
    before do
      create(
        :user_seen_subject,
        user: user,
        workflow: workflow,
        build_real_subjects: false,
        subject_ids: [1]
      )
      allow(FavoritesFinder).to receive(:find).and_return([])
      allow(SubjectWorkflowRetirements).to receive(:find).and_return([2])
    end

    let(:expected_context) do
      {
        user_seen_subject_ids: [1],
        favorite_subject_ids: [],
        retired_subject_ids: [2],
        user_has_finished_workflow: true,
        finished_workflow: false,
        selection_state: :normal,
        url_format: :get,
        select_context: true
      }
    end

    it 'should return the expected format' do
      expect(subject.format).to eq(expected_context)
    end
  end

  context "with as the selector selection_state changes" do
    it 'should return the expected state' do
      Subjects::Selector::SELECTION_STATE_ENUM.values.each do |selection_state|
        allow(selector).to receive(:selection_state).and_return(selection_state)
        expect(subject.format[:selection_state]).to eq(selection_state)
      end
    end
  end
end
