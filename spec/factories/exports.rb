FactoryGirl.define do
  factory :export do
    transient do
      export_source nil
    end

    before(:create) do |export, env|
      export.exportable = if env.export_source
                            export_source
                          else
                            create(:classificaiton)
                          end
    end
  end
end
