# spec/factories.rb

FactoryBot.define do
  factory :user do
    # ... other attributes ...

    # Use traits to build associations only when needed
    trait :with_account do
      after(:create) do |user|
        create(:account, user: user)
      end
    end

    # ... other traits ...
  end
end