shared_examples "select for incomplete_project" do
  let(:args) { opts }

  def run_limit_selection(limit)
    Subjects::PostgresqlSelection.new(
      workflow, user, (args || {}).merge(limit: limit)
    ).select
  end

  context "when a user has only seen a few subjects" do
    let(:uss) do
      subject_ids = sms_scope.sample(5).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end

    it 'should return an unseen subject with a limit of 1' do
      seen_ids = uss.subject_ids
      result = run_limit_selection(1).first
      expect(seen_ids).to_not include(result)
    end

    it 'should not have duplicates with a limit of 10' do
      result = run_limit_selection(10)
      expect(result).to match_array(result.to_a.uniq)
    end
  end

  context "when a user has seen most of the subjects" do
    let(:seen_count) { 20 }
    let!(:uss) do
      subject_ids = sms_scope.sample(seen_count).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end
    let(:unseen_count) { sms_count - seen_count }

    it 'should return the limit each time up to the unseen count' do
      (1..unseen_count).each do |limit|
        results_size = run_limit_selection(limit).length
        expect(results_size).to eq(limit)
      end
    end
  end
end
