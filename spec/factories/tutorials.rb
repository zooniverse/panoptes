FactoryGirl.define do

  factory :tutorial do
    language 'en'
    steps [{title: "asdfasdf", content: "asdfkajlsdf;"}, {title: 'asdfasdf', content: 'asdkfljds;lj'}]
    workflow
  end
end
