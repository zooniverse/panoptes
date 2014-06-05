FactoryGirl.define do
  factory :user do
    hash_func 'bcrypt'
    sequence(:email) {|n| "example#{n}@example.com"}
    password 'password'
    encrypted_password { User.new.send(:password_digest, 'password') }
    display_name 'New User'
    activated_state :active
    sequence(:login) { |n| "new_user_#{n}" }
    before(:create) do |u|
      u.uri_name = create(:uri_name, name: u.login, resource: u)
    end

    factory :insecure_user do
      hash_func 'sha1'
      password 'tajikistan'
      encrypted_password 'gFlanK5bXjD2YS7LSYndVJNGGdY='
      password_salt 'nK5bXjD2YS7LSYndVJNGGdY='
    end

    factory :project_owner do
      after(:create) do |user|
        n = Array(2..10).sample
        create_list(:project, n, owner: user)
      end
    end

    factory :user_group_member do
      after(:create) do |user|
        create_list(:membership, 1, user: user)
      end
    end

    factory :user_with_collections do
      after(:create) do |user|
        n = Array(2..10).sample
        create_list(:collection, n, owner: user)
      end
    end
  end
end
