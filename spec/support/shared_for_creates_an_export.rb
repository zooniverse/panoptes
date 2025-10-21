shared_examples_for "creates an export" do
  let(:create_params) do
    params = {
      media: {
        content_type: content_type,
        metadata: { recipients: create_list(:user, 1).map(&:id) }
      }
    }
    params.merge(resource_id: resource.id)
  end

  it 'should queue an export worker' do
    expect(export_worker).to receive(:perform_async).with(resource.id, resource.class.to_s.downcase, an_instance_of(Integer), an_instance_of(Integer))
    operation.with(object: resource).run!(create_params)
  end

  it 'should add the current user to the recipients list if none are specified' do
    params = create_params
    params[:media].delete(:metadata)
    export = operation.with(object: resource).run!(create_params)
    expect(export.metadata).to include("recipients" => [user.id])
  end

  it 'should update an existing export if one exists' do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: resource, type: medium_type, content_type: content_type, metadata: {})
    operation.with(object: resource).run!(create_params)
    export.reload
    expect(export.metadata).to include("recipients" => [user.id])
  end

  it 'should update the updated_at timestamp of the export' do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: resource, type: medium_type, content_type: content_type, metadata: {recipients: [user.id]}, updated_at: 5.days.ago)
    operation.with(object: resource).run!(create_params)
    export.reload
    expect(export.updated_at).to be_within(5.seconds).of(Time.zone.now)
  end

  it "includes the state in the metadata" do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: resource, type: medium_type, content_type: content_type, metadata: {recipients: [user.id]}, updated_at: 5.days.ago)
    operation.with(object: resource).run!(create_params)
    export.reload
    expect(export.metadata).to include("state" => "creating")
  end

  context 'with duplicate exports' do
    it 'reuses the most recently updated export and removes the rest' do
      params = create_params
      params[:media].delete(:metadata)

      old_export = create(
        :medium,
        linked: resource,
        type: medium_type,
        content_type: content_type,
        metadata: { recipients: [user.id], state: 'ready' },
        updated_at: 3.days.ago,
        created_at: 3.days.ago,
        content_disposition: 'attachment; filename="old-export.csv"'
      )

      recent_export = create(
        :medium,
        linked: resource,
        type: medium_type,
        content_type: content_type,
        metadata: { recipients: [user.id], state: 'ready' },
        updated_at: 1.day.ago,
        created_at: 1.day.ago,
        content_disposition: 'attachment; filename="recent-export.csv"'
      )

      result = nil

      expect do
        result = operation.with(object: resource).run!(create_params)
      end.to change { Medium.where(linked: resource, type: medium_type).count }.from(2).to(1)

      expect(result.id).to eq(recent_export.id)
      expect(Medium.exists?(old_export.id)).to be(false)
      expect(result.metadata).to include('state' => 'creating', 'recipients' => [user.id])
    end
  end
end
