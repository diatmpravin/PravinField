FactoryGirl.define do
  factory :user do
    name 'Test User'
    email 'example@example.com'
    password 'please'
    password_confirmation 'please'
    # required if the Devise Confirmable module is used
    #confirmed_at Time.now
  end
  
  factory :import do
    import_date '2011-10-01'
    format 'csv'
    status 'done'
  end
end
