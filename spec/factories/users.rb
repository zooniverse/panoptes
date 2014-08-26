FactoryGirl.define do
  factory :user do
    hash_func 'bcrypt'
    sequence(:email) {|n| "example#{n}@example.com"}
    password 'password'
    encrypted_password { User.new.send(:password_digest, 'password') }
    display_name 'New User'
    credited_name 'Dr User'
    activated_state :active
    sequence(:login) { |n| "new_user_#{n}" }
    global_email_communication true
    project_email_communication true
    admin false

    after(:build) do |user|
      unless user.owner_name
        user.owner_name = build(:owner_name, name: user.login, resource: user)
      end
    end

    factory :insecure_user do
      hash_func 'sha1'
      password 'tajikistan'
      encrypted_password 'gFlanK5bXjD2YS7LSYndVJNGGdY='
      password_salt 'nK5bXjD2YS7LSYndVJNGGdY='
    end

    factory :project_owner do
      after(:create) do |user|
        create_list(:project, 2, owner: user)
      end
    end

    factory :user_group_member do
      after(:create) do |user|
        create_list(:membership, 1, user: user)
      end
    end

    factory :user_with_collections do
      after(:create) do |user|
        create_list(:collection, 2, owner: user)
      end
    end

    factory :inactive_user do
      activated_state :inactive
      display_name 'deleted_user'
      email 'deleted_user@zooniverse.org'
      login '1234567890'
    end

    factory :user_with_languages do
      languages ['en', 'es', 'fr-ca']
    end

    factory :admin_user do
      after(:build) do |u|
        u.add_role :admin
      end
    end
  end

  factory :omniauth_user, class: :user do
    sequence(:login) { |n| "new_user_#{n}" }
    sequence(:email) {|n| "example#{n}@example.com"}
    password 'password'
    display_name 'New User'
    credited_name 'Dr New User'
    activated_state :active
    languages ['en', 'es', 'fr-ca']
    after(:build) do |u|
      unless u.owner_name
        u.owner_name = build(:owner_name,
                              name: u.login,
                              resource: u)
      end
      create_list(:authorization, 1, user: u, provider: 'facebook', uid: '12345')
    end
  end
end
