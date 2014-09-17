shared_examples "is updatable" do
  context "an authorized user" do
    let(:updated_resource) { resource.reload }
    
    before(:each) do
      default_request scopes: scopes, user_id: authorized_user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end
    
    it 'should update supplied attributes' do
      expect(updated_resource.send(test_attr)).to eq(test_attr_value)
      
    end

    it 'should update any included links' do
      expect(updated_resource.send(test_relation)
             .map(&:id)).to include(*test_relation_ids)
    end

    it 'should return 200' do
      expect(response.status).to eq(200)
    end

    it_behaves_like 'an api response'
  end

  context "an unauthorized user" do
    before(:each) do
      user = if defined?(unauthorized_user)
               unauthorized_user
             else
               create(:user)
             end
      
      default_request scopes: scopes, user_id: user.id
      params = update_params.merge(id: resource.id)
      put :update, params
    end

    it 'should return 403' do
      expect(response.status).to eq(403)
    end

    it 'should not have modified the resource' do
      expect(resource_class.find(resource.id)).to eq(resource)
    end
  end
end

shared_examples "has updatable links" do
  describe "#update_links" do
    context "many-to-many" do
      it 'should add the new relations to the resource' do
        post :update_links, {id: resource.id,
                             link_relation: :subjects,
                             subjects: subjects.map(&:id).map(&:to_s)}
        expect(resource.subjects).to include(*subjects)
      end

      it 'should error when the relation does not match the link' do
        expect do
          post :update_links, {id: resource.id,
                               link_relation: :sujbcts,
                               subjects: subjects.map(&:id).map(&:to_s)}
        end.to raise_error(Api::BadLinkParams)
      end
    end

    context "one-to-many" do
      it 'should add the new relation to the resource' do
        project = create(:project)
        post :update_links, {id: resource.id,
                             link_relation: :project,
                             project: project.id}
        resource.reload
        expect(resource.project).to eq(project)
      end
    end

    context "polymorphic" do
      it 'should add the new relation to the resource' do
        group = create(:user_group)
        post :update_links, {id: resource.id,
                             link_relation: :owner,
                             owner: { id: group.id,
                                     type: "user_group"}}
        expect(resource.owner).to eq(group)
      end
    end
  end
end

shared_examples "has destructable links" do
  describe "#destroy_links" do
    context 'habtm' do
      before(:each) do
        resource.subjects = subjects
        resource.save!
      end
      
      it 'should remove included relations' do
        delete :destroy_links, {id: resource.id,
                                link_relation: :subjects,
                                link_ids: subjects[0..1].map(&:id).join(',')}
        resource.reload
        expect(resource.subjects).to include(*subjects[2..-1])
        expect(resource.subjects).to_not include(*subjects[0..1])
      end

      it 'should not destroy then items' do
        expect do
          delete :destroy_links, {id: resource.id,
                                  link_relation: :subjects,
                                  link_ids: subjects[0..1].map(&:id).join(',')}
        end.to_not change{ Subject.count }
      end
    end

    context 'has-many' do
      it 'should remove included relations'

      it 'should destroy the items'
    end
  end
end
