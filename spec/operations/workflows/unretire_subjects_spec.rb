require 'spec_helper'

describe Workflows::UnretireSubjects do 
    let(:api_user) { ApiUser.new(build_stubbed(:user)) }
    let (:workflow) { create(:workflow) }
    let(:subject_set) { create(:subject_set, project: workflow.project, workflows: [workflow]) }
    let(:subject_set_id) { subject_set.id }

    it "should unretire given subjects with subject ids for the workflow", :focus => true do 
        
    end
end