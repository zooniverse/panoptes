FactoryGirl.define do
  factory :user do
    hash_func 'bcrypt'
    sequence(:email) {|n| "example#{n}@example.com"}
    password 'password'
    encrypted_password { User.new.send(:password_digest, 'password') }
    name 'New User'
    login 'new_user'

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
  end
end
