FactoryGirl.define do
  factory :classification_export_row do
    transient do
      classification nil
    end

    before(:create) do |export_row, env|
      export_row.classification = if env.classification
                                    classification
                                  else
                                    create(:classificaiton)
                                  end
    end
  end
end
