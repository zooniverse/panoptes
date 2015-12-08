shared_examples "optimistically locked" do
  it 'should not write to the db if a record has the lock' do
    model_id = create(locked_factory).id
    m1 = described_class.find(model_id)
    m2 = described_class.find(model_id)

    m1.update_attributes(locked_update)
    m1.save

    expect do
      m2.update_attributes(locked_update)
      m2.save
    end.to raise_error(ActiveRecord::StaleObjectError)

  end
end
