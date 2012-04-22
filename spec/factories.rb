FactoryGirl.define do
  
  factory :user do
    name 'Test User'
    sequence(:email) { |n| "example-#{n}@example.com" }
    password 'please'
    password_confirmation 'please'
    # required if the Devise Confirmable module is used
    #confirmed_at Time.now
  end
  
  factory :import do
    import_date '2011-10-01'
  end
  
  factory :sku_pattern do
    pattern 'some pattern'
    granularity 'Variant'
    delimiter '-'
    brand
  end
  
end
