FactoryBot.define do
  factory :tutorial do
    language 'en'
    steps [{media: "asdfasdf", content: "asdfkajlsdf;"}, {media: 'asdfasdf', content: 'asdkfljds;lj'}]
    display_name "A Tutorial"
    project
  end
end
