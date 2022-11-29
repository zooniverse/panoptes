require 'spec_helper'

describe CsvDumps::FindsMedium do
  let(:dump_type) { "project_classifications_export" }
  let(:resource_file_path) { [dump_type, resource.id.to_s] }
  let(:resource) { create :project }
  let(:content_disposition) { "attachment; filename=\"foo.csv\"" }

  let(:finder) {
    described_class.new(medium_id, resource, "classifications")
  }

  context "when medium does not exist yet" do
    let(:medium_id) { nil }

    it "should create a linked media resource" do
      expect(Medium).to receive(:create!).and_call_original
      finder.medium
    end

    it "should not fail to create a linked media resource" do
      expect do
        finder.medium
      end.to_not raise_error
    end
  end

  context "when medium already exists" do
    let(:receivers) { create_list(:user, 2) }
    let(:metadata) { { "recipients" => receivers.map(&:id) } }
    let(:medium) do
      create(:medium, metadata: metadata, linked: resource, content_type: "text/csv", type: dump_type)
    end
    let(:medium_id) { medium.id }

    it 'should update the path on the object' do
      finder.medium
      medium.reload
      expect(medium.path_opts).to match_array([dump_type, resource.id.to_s])
    end

    it 'should set the medium to private' do
      finder.medium
      medium.reload
      expect(medium.private).to be true
    end

    it 'should update the medium content_type to csv' do
      medium.update_column(:content_type, "text/html")
      finder.medium
      medium.reload
      expect(medium.content_type).to eq("text/csv")
    end

    it 'should update the medium content_disposition' do
      finder.medium
      medium.reload
      name = resource.slug.split("/")[1]
      type = medium.type.match(/\Aproject_(\w+)_export\z/)[1]
      ext = MIME::Types[medium.content_type].first.extensions.first
      file_name = "#{name}-#{type}.#{ext}"
      expect(medium.content_disposition).to eq("attachment; filename=\"#{file_name}\"")
    end

    context 'when the resource is a subject-set' do
      let(:resource) { create :subject_set }

      it 'should update the medium content_disposition' do
        finder.medium
        medium.reload
        type = medium.type.match(/\Aproject_(\w+)_export\z/)[1]
        ext = MIME::Types[medium.content_type].first.extensions.first
        file_name = "#{resource.display_name.parameterize}-#{type}.#{ext}"
        expect(medium.content_disposition).to eq("attachment; filename=\"#{file_name}\"")
      end
    end
  end
end
