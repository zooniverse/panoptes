require 'spec_helper'

RSpec.describe Subjects::PostgresqlInOrderSelection do
  let(:project) { create :project }
  let(:workflow) { create(:workflow_with_subject_sets, project: project) }
  let(:uploader) { workflow.project.owner }
  let(:subject_set) { workflow.subject_sets.first }
  let(:available) { SetMemberSubject.all }
  let(:limit) { 10 }
  let(:selector) { Subjects::PostgresqlInOrderSelection.new(available, limit) }

  before do
    create_list(:subject, 25, project: project, uploader: uploader).each do |subject|
      create(:set_member_subject, subject: subject, subject_set: subject_set)
    end
  end

  def update_sms_priorities
    SetMemberSubject.where(priority: nil).each_with_index do |sms, index|
      sms.update_column(:priority, index+1)
    end
  end

  describe "priority selection" do
    let(:ordered) { available.order(priority: :asc).pluck(:id) }
    let(:limit) { available.size }

    before do
      update_sms_priorities
    end

    it 'should select subjects in asc order of the priority field' do
      result = selector.select
      expect(result).to eq(ordered)
    end

    context "with 1 limit for prepend test" do
      let(:limit) { 1 }

      it 'should allow negative numbers to prepend the sort list' do
        sms_subject = create(:subject, project: project, uploader: uploader)
        sms = create(:set_member_subject, subject: sms_subject, subject_set: subject_set, priority: -10.to_f)
        first_id = selector.select.first
        expect(first_id).to eq(sms.id)
      end
    end
  end
end
