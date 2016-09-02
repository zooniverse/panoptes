require 'spec_helper'

describe ProjectCounter do
  let(:project) { create(:project_with_workflows) }
  let(:counter) { ProjectCounter.new(project) }

  describe 'volunteers' do

    it "should return 0 if there are none" do
      expect(counter.volunteers).to eq(0)
    end

    it "should return 2" do
      2.times do
        c = create(:classification, project: project)
        create(:user_project_preference, project: project, user: c.user)
      end
      expect(counter.volunteers).to eq(2)
    end
  end

  describe 'classifications' do

    it "should return 0 if there are none" do
      expect(counter.classifications).to eq(0)
    end

    it "should return 2" do
      project.workflows.each do |w|
        w.update_column(:classifications_count, 1)
      end
      expect(counter.classifications).to eq(2)
    end
  end
end
