# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V1::SubjectGroupsController, type: :controller do
  let(:api_resource_name) { 'subject_groups' }
  let(:api_resource_attributes) do
    %w[id context key created_at updated_at]
  end
  let(:api_resource_links) do
    %w[subject_groups.group_subject subject_groups.subjects subject_groups.project]
  end
  let(:resource) { create(:subject_group) }
  let(:authorized_user) { resource.project.owner }

  let(:scopes) { %w[public] }
  let(:resource_class) { SubjectGroup }

  describe '#index' do
    let(:subject_group) { create(:subject_group) }
    let(:private_project) { create(:project, private: true) }
    let(:private_resource) do
      create(:subject_group, project: private_project)
    end
    let(:n_visible) { 1 }

    before { resource }

    it_behaves_like 'is indexable'
  end

  describe '#show' do
    it_behaves_like 'is showable'
  end
end
