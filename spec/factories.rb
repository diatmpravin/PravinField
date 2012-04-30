FactoryGirl.define do
  
  factory :user do
    name 'Test User'
    sequence(:email) { |n| "example-#{n}@example.com" }
    password 'please'
    password_confirmation 'please'
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
  
  factory :listing do
    #mws_request
    product
    store
    operation_type 'Update'
  end
  
  factory :mws_message do
    
  end
  
	factory :vendor do
		sequence(:name) { |n| "Safilo-#{n}" }
	end
	
	factory :brand do
  	vendor
  	sequence(:name) { |n| "Carrera-#{n}" }
	end
		
	factory :product do
		brand
  	sequence(:name) { |n| "Carrera 127/S-#{n}" }
		sequence(:sku) { |n| "23423341#{n}" }
	end

	factory :store do
		sequence(:name) { |n| "FieldDay-#{n}" }
		authenticated_url 'https://10631e6948f35b5f0e390c16c5b7c810:c9b2449f54de4b0ca0dbfb9ebd31ffc2@rippin-group7856.myshopify.com/admin'
    queue_flag 'False'
    verify_flag 'True'
	end
	
	factory :variant do
		product
		#color1 'Brown'
		#color2 'Metallic Green'
		sequence(:sku) { |n| "234233411-V045C#{n}" }
		sequence(:color1_code) { "V045C#{n}" }
		#cost_price 129.99
	end
	
	factory :variant_image do
		variant
		image_width 400
		sequence(:unique_image_file_name) { |n| "/test/fixtures/gift-#{n}.png" }
	end
	
	factory :mws_order do
		store
		mws_response
		sequence(:amazon_order_id) { |n| "002-2650369-3346644-#{n}" }
		purchase_date Time.now 
	end

	factory :mws_response do
		mws_request
		amazon_order_id "MyString"
	end

	factory :mws_request do
		store
	end
	
	factory :mws_order_item do
		mws_order
		sequence(:amazon_order_item_id) { |n| "212343244329590-#{n}" }
		sequence(:seller_sku) { |n| "23423341-12327859-V045C-#{n}-AZ3" }
	end
	
	factory :omx_request do
		mws_order
	end
	
	factory :omx_response do
		omx_request
	end

  factory :variant_update do
    variant
    import
  end

  factory :state do
    sequence(:raw_state) { |n| "Pennsylvania-#{n}" }
    clean_state "PA"
  end

  factory :sub_variant do
    variant
    sequence(:sku) { |n| "234233411-V045C1-XL#{n}" } 
  end

  factory :sku_mapping do
    sequence(:sku) { "234233411-V045C1-XL#{n}" }
    sku_mapable_type 'SubVariant'
    sku_mapable_id 1
  end  
  
end
