FactoryGirl.define do
  factory :tutorial do
    language 'en'
    steps [{media: "asdfasdf", content: "asdfkajlsdf;"}, {media: 'asdfasdf', content: 'asdkfljds;lj'}]
    project
  end
end
