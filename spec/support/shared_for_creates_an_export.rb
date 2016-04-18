shared_examples_for "creates an export" do
  let(:create_params) do
    params = {
      media: {
        content_type: content_type,
        metadata: { recipients: create_list(:user, 1).map(&:id) }
      }
    }
    params.merge(project_id: project.id)
  end

  it 'should queue an export worker' do
    expect(export_worker).to receive(:perform_async).with(project.id, an_instance_of(Fixnum), an_instance_of(Fixnum))
    operation.with(project: project).run!(create_params)
  end

  it 'should add the current user to the recipients list if none are specified' do
    params = create_params
    params[:media].delete(:metadata)
    export = operation.with(project: project).run!(create_params)
    expect(export.metadata).to include("recipients" => [user.id])
  end

  it 'should update an existing export if one exists' do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: project, type: medium_type, content_type: content_type, metadata: {})
    operation.with(project: project).run!(create_params)
    export.reload
    expect(export.metadata).to include("recipients" => [user.id])
  end

  it 'should update the updated_at timestamp of the export' do
    params = create_params
    params[:media].delete(:metadata)
    export = create(:medium, linked: project, type: medium_type, content_type: content_type, metadata: {recipients: [user.id]}, updated_at: 5.days.ago)
    operation.with(project: project).run!(create_params)
    export.reload
    expect(export.updated_at).to be_within(5.seconds).of(Time.zone.now)
  end
end
