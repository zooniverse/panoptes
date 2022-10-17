shared_examples "it syncs the resource translation strings" do |non_translatable_attributes_possible: true|
  it 'should queue a translation sync worker if translatable attributes change' do
    expect(TranslationSyncWorker)
      .to receive(:perform_async)
      .with(translated_klass_name, translated_resource_id, translated_language)
    default_request scopes: scopes, user_id: authorized_user.id
    post controller_action, params: translatable_action_params
  end

  if non_translatable_attributes_possible
    it 'should not queue a worker when only other attributes change' do
      expect(TranslationSyncWorker).not_to receive(:perform_async)
      default_request scopes: scopes, user_id: authorized_user.id
      post controller_action, params: non_translatable_action_params
    end
  end
end
