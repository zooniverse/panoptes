require 'spec_helper'

describe ProjectCounter do
  let(:project) { create(:project) }
  let(:counter) { ProjectCounter.new(project) }

  shared_examples 'a project counter' do |counter_name|
    let(:now) { DateTime.now.utc }

    it "should return 0 if there are none" do
      expect(counter.send(counter_name)).to eq(0)
    end

    context "with classifications" do
      before do
        2.times do
          c = create(:classification, project: project)
          create(:user_project_preference, project: project, user: c.user)
        end
      end

      it "should return 2" do
        expect(counter.send(counter_name)).to eq(2)
      end

      it "should respect the project launch date" do
        allow(counter).to receive(:launch_date).and_return(now)
        expect(counter.send(counter_name)).to eq(0)
        allow(counter).to receive(:launch_date).and_return(now-1.day)
        expect(counter.send(counter_name)).to eq(2)
      end
    end
  end

  describe 'volunteers' do
    it_should_behave_like 'a project counter', :volunteers
  end

  describe 'classifications' do
    it_should_behave_like 'a project counter', :classifications
  end
end
