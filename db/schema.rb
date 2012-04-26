# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120422133158) do

  create_table "brands", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.datetime "icon_updated_at"
    t.float    "default_markup",    :default => 1.0
  end

  add_index "brands", ["vendor_id"], :name => "index_brands_on_vendor_id"

  create_table "imports", :force => true do |t|
    t.string   "format"
    t.string   "input_file_file_name"
    t.string   "input_file_content_type"
    t.integer  "input_file_file_size"
    t.datetime "input_file_updated_at"
    t.string   "error_file_file_name"
    t.string   "error_file_content_type"
    t.integer  "error_file_file_size"
    t.datetime "error_file_updated_at"
    t.datetime "import_date"
    t.string   "status"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "listings", :force => true do |t|
    t.integer  "product_id"
    t.integer  "store_id"
    t.string   "handle"
    t.string   "foreign_id"
    t.integer  "mws_request_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.datetime "inactive_timestamp"
  end

  create_table "mws_order_items", :force => true do |t|
    t.string   "asin"
    t.string   "amazon_order_item_id"
    t.string   "seller_sku"
    t.string   "title"
    t.integer  "quantity_ordered"
    t.integer  "quantity_shipped"
    t.float    "item_price"
    t.string   "item_price_currency"
    t.float    "shipping_price"
    t.string   "shipping_price_currency"
    t.float    "gift_price"
    t.string   "gift_price_currency"
    t.float    "item_tax"
    t.string   "item_tax_currency"
    t.float    "shipping_tax"
    t.string   "shipping_tax_currency"
    t.float    "gift_tax"
    t.string   "gift_tax_currency"
    t.float    "shipping_discount"
    t.string   "shipping_discount_currency"
    t.float    "promotion_discount"
    t.string   "promotion_discount_currency"
    t.string   "gift_wrap_level"
    t.string   "gift_message_text"
    t.integer  "mws_order_id"
    t.string   "amazon_order_id"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "mws_response_id"
    t.string   "clean_sku"
    t.integer  "product_id"
    t.integer  "variant_id"
    t.integer  "sub_variant_id"
  end

  add_index "mws_order_items", ["amazon_order_id"], :name => "index_mws_order_items_on_amazon_order_id"
  add_index "mws_order_items", ["clean_sku"], :name => "index_mws_order_items_on_clean_sku"
  add_index "mws_order_items", ["mws_order_id"], :name => "index_mws_order_items_on_mws_order_id"
  add_index "mws_order_items", ["mws_response_id"], :name => "index_mws_order_items_on_mws_response_id"

  create_table "mws_orders", :force => true do |t|
    t.string   "amazon_order_id"
    t.string   "seller_order_id"
    t.datetime "purchase_date"
    t.datetime "last_update_date"
    t.string   "order_status"
    t.string   "fulfillment_channel"
    t.string   "sales_channel"
    t.string   "order_channel"
    t.string   "ship_service_level"
    t.float    "amount"
    t.string   "currency_code"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "address_line_3"
    t.string   "city"
    t.string   "county"
    t.string   "district"
    t.string   "state_or_region"
    t.string   "postal_code"
    t.string   "country_code"
    t.string   "phone"
    t.integer  "number_of_items_shipped"
    t.integer  "number_of_items_unshipped"
    t.string   "marketplace_id"
    t.string   "buyer_name"
    t.string   "buyer_email"
    t.integer  "mws_response_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.string   "shipment_service_level_category"
    t.string   "name"
    t.integer  "store_id"
  end

  add_index "mws_orders", ["amazon_order_id"], :name => "index_mws_orders_on_amazon_order_id"
  add_index "mws_orders", ["mws_response_id"], :name => "index_mws_orders_on_mws_response_id"
  add_index "mws_orders", ["purchase_date"], :name => "index_mws_orders_on_purchase_date"
  add_index "mws_orders", ["store_id"], :name => "index_mws_orders_on_store_id"

  create_table "mws_requests", :force => true do |t|
    t.string   "amazon_request_id"
    t.string   "request_type"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "store_id"
    t.integer  "mws_request_id"
    t.string   "feed_type"
    t.text     "message"
  end

  add_index "mws_requests", ["mws_request_id"], :name => "index_mws_requests_on_mws_request_id"

  create_table "mws_responses", :force => true do |t|
    t.integer  "mws_request_id"
    t.string   "amazon_request_id"
    t.text     "next_token"
    t.datetime "last_updated_before"
    t.datetime "created_before"
    t.string   "request_type"
    t.integer  "page_num"
    t.string   "error_code"
    t.text     "error_message"
    t.string   "amazon_order_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "feed_submission_id"
    t.string   "processing_status"
  end

  add_index "mws_responses", ["amazon_order_id"], :name => "index_mws_responses_on_amazon_order_id"
  add_index "mws_responses", ["mws_request_id"], :name => "index_mws_responses_on_mws_request_id"

  create_table "omx_requests", :force => true do |t|
    t.string   "request_type"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "mws_order_id"
    t.string   "keycode"
    t.string   "verify_flag",  :default => "True"
    t.string   "queue_flag",   :default => "False"
    t.string   "vendor"
    t.string   "store_code"
  end

  add_index "omx_requests", ["mws_order_id"], :name => "index_omx_requests_on_mws_order_id"

  create_table "omx_responses", :force => true do |t|
    t.integer  "omx_request_id"
    t.integer  "success"
    t.string   "ordermotion_response_id"
    t.string   "ordermotion_order_number"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.text     "error_data"
  end

  add_index "omx_responses", ["omx_request_id"], :name => "index_omx_responses_on_omx_request_id"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.text     "meta_description"
    t.string   "meta_keywords"
    t.integer  "brand_id"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "sku"
    t.string   "category",         :default => "Sunglasses"
    t.string   "product_type",     :default => "Accessory"
    t.string   "variation_theme",  :default => "Color"
    t.string   "department"
    t.datetime "file_date"
    t.string   "amazon_template"
    t.text     "keywords"
    t.text     "keywords2"
    t.text     "keywords3"
    t.string   "sku2"
  end

  add_index "products", ["brand_id"], :name => "index_products_on_brand_id"
  add_index "products", ["category"], :name => "index_products_on_category"
  add_index "products", ["sku"], :name => "index_products_on_base_sku"

  create_table "sku_mappings", :force => true do |t|
    t.string   "sku"
    t.string   "sku_mapable_type"
    t.integer  "sku_mapable_id"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "source",           :default => "manual"
  end

  add_index "sku_mappings", ["sku"], :name => "index_sku_mappings_on_sku", :unique => true

  create_table "sku_patterns", :force => true do |t|
    t.integer  "brand_id"
    t.string   "pattern"
    t.string   "condition"
    t.string   "granularity", :default => "Variant"
    t.float    "priority"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "delimiter",   :default => "-"
  end

  create_table "states", :force => true do |t|
    t.string   "raw_state"
    t.string   "clean_state"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "states", ["raw_state"], :name => "index_states_on_raw_state"

  create_table "stores", :force => true do |t|
    t.string   "name"
    t.string   "store_type",             :default => "MWS"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "order_results_per_page", :default => 100
    t.integer  "max_order_pages",        :default => 10
    t.string   "queue_flag",             :default => "False"
    t.string   "verify_flag",            :default => "True"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.string   "authenticated_url"
  end

  create_table "sub_variants", :force => true do |t|
    t.integer  "variant_id"
    t.string   "sku"
    t.string   "upc"
    t.string   "size"
    t.string   "availability"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.text     "asin"
    t.text     "size_code"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "role"
    t.string   "name"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "variant_images", :force => true do |t|
    t.integer  "variant_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.string   "image_file_size"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.datetime "image_updated_at"
    t.string   "unique_image_file_name"
    t.integer  "image_width"
    t.integer  "image_height"
  end

  add_index "variant_images", ["unique_image_file_name"], :name => "index_variant_images_on_unique_image_file_name"
  add_index "variant_images", ["variant_id"], :name => "index_variant_images_on_variant_id"

  create_table "variant_updates", :force => true do |t|
    t.integer  "variant_id"
    t.float    "price"
    t.float    "cost_price"
    t.string   "availability"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.datetime "update_date"
    t.integer  "import_id"
  end

  create_table "variants", :force => true do |t|
    t.integer  "product_id"
    t.string   "sku"
    t.decimal  "price"
    t.decimal  "cost_price"
    t.decimal  "weight"
    t.decimal  "height"
    t.decimal  "width"
    t.decimal  "depth"
    t.string   "size"
    t.string   "color1"
    t.string   "color2"
    t.string   "color1_code"
    t.string   "color2_code"
    t.string   "availability"
    t.datetime "deleted_at"
    t.boolean  "is_master"
    t.integer  "position"
    t.string   "amazon_product_id"
    t.string   "amazon_product_name"
    t.text     "amazon_product_description"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.string   "upc"
    t.float    "sale_price"
    t.float    "msrp"
    t.string   "currency"
    t.integer  "leadtime_to_ship"
    t.text     "asin"
    t.string   "size_code"
  end

  add_index "variants", ["amazon_product_id"], :name => "index_variants_on_amazon_product_id"
  add_index "variants", ["product_id"], :name => "index_variants_on_product_id"
  add_index "variants", ["sku"], :name => "index_variants_on_sku"

  create_table "vendors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.datetime "scraped_at"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.string   "base_url"
    t.string   "login_url"
    t.string   "username"
    t.string   "password"
  end

end
