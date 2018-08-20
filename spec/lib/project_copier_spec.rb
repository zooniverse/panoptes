require 'spec_helper'

describe ProjectCopier do
  describe '#copy' do
    let(:project) { create(:full_project, build_extra_contents: true)}
    let(:copyist) { create(:user) }
    let!(:tags) { create(:tag, resource: project) }
    let!(:field_guide) { create(:field_guide, project: project) }
    let!(:page) { create(:project_page, project: project) }
    let!(:project_translation) { create(:project_translation, translated: project) }

    context "a template project" do
      let(:copied_project) { described_class.copy(project.id, copyist.id) }

      it "returns a valid project" do
        expect(described_class.copy(project.id, copyist.id)).to be_valid
      end

      it "sets the owner to the api_user" do
        expect(copied_project.owner).to eq(copyist)
      end

      it "renames a project when the owner is copying their own project" do
        new_copy = described_class.copy(project.id, project.owner.id)
        expect(new_copy.display_name).to include("(copy)")
      end

      it "has matching attributes" do
        expect(copied_project.display_name).to eq(project.display_name)
      end

      it "has updated attributes" do
        expect(copied_project.live).to be false
        expect(copied_project.launch_approved).to be false
      end

      it "strips the template config" do
        expect(copied_project.configuration).not_to include(:template)
      end

      it "adds the source project id to the copied project's configuration" do
        expect(copied_project.configuration[:source_project_id]).to be(project.id)
      end

      it "has valid copied workflows" do
        expect(copied_project.workflows.first).to be_valid
        expect(copied_project.workflows.first.display_name).to eq(project.workflows.first.display_name)
      end

      it "has other valid copied associations" do
        expect(copied_project.tags.first).to be_valid
        expect(copied_project.field_guides.first).to be_valid
        expect(copied_project.pages.first).to be_valid
        expect(copied_project.translations.first).to be_valid
      end
    end
  end
end
