require 'spec_helper'

describe ClassificationSerializer do
  let(:classification) { create(:classification) }

  it_should_behave_like "a panoptes restpack serializer" do
    let(:resource) { classification }
    let(:includes) { [:project, :user, :user_group, :workflow] }
    let(:preloads) { [:subjects] }
  end

  it_should_behave_like "a no count serializer" do
    let(:resource) { classification }
  end

  describe "nested collection routes" do
    before do
      classification
    end

    it "should return the correct href urls" do
      %w(gold_standard incomplete project).each do |collection_route|
        context = {url_suffix: collection_route}
        result = ClassificationSerializer.page({}, Classification.all, context)
        meta = result[:meta][:classifications]
        expect(meta[:first_href]).to eq("/classifications/#{collection_route}")
        expect(meta[:previous_href]).to eq("/classifications/#{collection_route}?page=0")
        expect(meta[:next_href]).to eq("/classifications/#{collection_route}?page=2")
        expect(meta[:last_href]).to eq("/classifications/#{collection_route}?page=0")
      end
    end

    context "project context with last_id param present" do
      let(:project) { classification.project }
      let(:last_id) { classification.id }
      let(:scope) do
        Classification.where(project_id: project.id).after_id(last_id)
      end
      let(:prefix) { "/classifications?last_id=" }
      let(:suffix) { "&page_size=1&project_id=#{project.id}" }
      let(:params) do
        { project_id: project.id, last_id: last_id, page_size: 1 }
      end

      it "should insert the highest page set id into the next_href" do
        second = create(:classification, project: project)
        result = ClassificationSerializer.page(params, scope, {})
        meta = result[:meta][:classifications]
        expect(meta[:previous_href]).to eq("#{prefix}#{last_id}#{suffix}")
        expect(meta[:next_href]).to eq("#{prefix}#{second.id}#{suffix}")
      end

      it "should construct valid hrefs when there is no data" do
        page2_params = params.merge({page: 2})
        result = ClassificationSerializer.page(page2_params, scope, {})
        meta = result[:meta][:classifications]
        expect(meta[:previous_href]).to eq("#{prefix}#{last_id}#{suffix}")
        expect(meta[:next_href]).to be_nil
      end
    end
  end
end
