require 'spec_helper'

describe GoldStandardAnnotationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:project) { create :project, owner: resource_owner }
    let(:workflow) { create(:workflow, project: project, public_gold_standard: true) }

    let(:public_gsa) { build(:gold_standard_annotation, project: project, workflow: workflow, user: resource_owner) }
    let(:private_gsa) { build(:gold_standard_annotation) }

    before do
      public_gsa.save!
      private_gsa.save!
    end

    subject do
      PunditScopeTester.new(GoldStandardAnnotation, api_user)
    end

    context 'as a non-admin' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([public_gsa]) }
    end

    context 'as an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      its(:index) { is_expected.to match_array([public_gsa, private_gsa]) }
    end
  end
end
