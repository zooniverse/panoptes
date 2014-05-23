FactoryGirl.define do
  factory :user do
    hash_func 'bcrypt'
    sequence(:email) {|n| "example#{n}@example.com"}
    encrypted_password { User.new.send(:password_digest, 'password') }
    name 'New User'
    login 'new_user'

    factory :insecure_user do
      hash_func 'sha1'
      encrypted_password 'gFlanK5bXjD2YS7LSYndVJNGGdY='
      password_salt 'nK5bXjD2YS7LSYndVJNGGdY='
    end
  end
end
