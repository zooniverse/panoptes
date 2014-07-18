FactoryGirl.define do
  factory :authorization do
    user
    provider "facebook"
    uid "12345"
    token "asd;lkfjas;dflkjasdfasdfha;vznxfhjasd;lfkhaweiuha;sdlkfjasdf"
    expires_at 1.year.from_now
  end
end
