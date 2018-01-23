shared_examples "it syncs the resource translation strings" do
  it 'should queue a translation sync worker' do
    expect(TranslationSyncWorker)
      .to receive(:perform_async)
      .with(translated_klass_name, translated_resource_id, translated_language)
  end

  after do
    default_request scopes: scopes, user_id: authorized_user.id
    post controller_action, controller_action_params
  end
end
