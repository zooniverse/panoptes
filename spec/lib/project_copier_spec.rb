require 'spec_helper'

describe ProjectCopier do
  describe '::copy' do
    let(:project) { create(:full_project, build_extra_contents: true)}
    let(:copyist) { create(:user) }
    let(:tags) { create(:tag, resource: project) }
    let(:field_guide) { create(:field_guide, project: project) }
    let(:page) { create(:project_page, project: project) }

    context "a template project" do
      let(:copied_project) { described_class.copy(project.id, copyist.id) }
      # "and just test the returned copy"

      # or...

      # subject(:copy) do
        # -> { described_class.copy(project.id, copyist.id) }
      # end
      # "and test the method call but pay the cost of copying over and over again for as many things as I test"

      it "returns a valid project" do
        binding.pry
      #   "just that it exists and saved"
      end

      it "has matching attributes (...but that's what dup does so why test it?)" do
      end

      it "has valid workflows" do
      end

      it "...has an avatar? How much of this do I have to do? Do I test every association?" do
      end
    end
  end
end
