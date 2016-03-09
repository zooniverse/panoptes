shared_examples "select for incomplete_project" do
  let(:args) { opts }
  let(:selector) { Subjects::PostgresqlSelection.new(workflow, user, args) }

  let(:sms_scope) do
    if ss_id = args[:subject_set_id]
      SetMemberSubject.where(subject_set_id: ss_id)
    else
      SetMemberSubject.all
    end
  end

  let(:unseen_count) do
    scoped_seen_count = if ss_id = args[:subject_set_id]
                          group_sms = SetMemberSubject.where(subject_set_id: ss_id)
                          group_sms.where(subject_id: uss.subject_ids).count
                        else
                          seen_count
                        end
    sms_scope.count - scoped_seen_count
  end

  context "when a user has only seen a few subjects" do
    let(:seen_count) { 5 }
    let(:limit) { nil }
    let(:args) { opts.merge(limit: limit) }
    let!(:uss) do
      subject_ids = sms_scope.sample(seen_count).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end

    context "with a limit of 1" do
      let(:limit) { 1 }

      it 'should return an unseen subject' do
        selected = selector.select.first
        expect(uss.subject_ids).to_not include(selected)
      end
    end

    context "with a limit of 10" do
      let(:limit) { 10 }

      it 'should no have duplicates' do
        result = selector.select
        expect(result).to match_array(result.to_a.uniq)
      end
    end

    # Account for the loop cut off limit constructing the random sample
    it 'should always return an approximate sample of subjects up to the unseen limit' do
      unseen_count.times do |n|
        limit = n+1
        results_size = Subjects::PostgresqlSelection.new(workflow, user, (args || {}).merge(limit: limit)).select.length
        expect(results_size).to be_between(results_size, limit).inclusive
      end
    end
  end

  context "when a user has seen most of the subjects" do
    let(:seen_count) { 20 }
    let!(:uss) do
      subject_ids = sms_scope.sample(seen_count).map(&:subject_id)
      create(:user_seen_subject, user: user, subject_ids: subject_ids, workflow: workflow)
    end

    it 'should return as many subjects as possible' do
      unseen_count.times do |n|
        limit = n+unseen_count
        results_size = Subjects::PostgresqlSelection.new(workflow, user, (args || {}).merge(limit: limit)).select.length
        expect(results_size).to be_between(results_size, limit).inclusive
      end
    end
  end
end
