shared_examples_for 'is translatable' do
  it 'can automatically sync the initial translation' do
    model.save!
    TranslationSyncWorker.new.perform(model.class.to_s, model.id, model.translatable_language)
    expect(Translation.count).to eq(1)
  end
end
