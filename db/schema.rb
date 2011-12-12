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

ActiveRecord::Schema.define(:version => 20111212010659) do

  create_table "brands", :force => true do |t|
    t.string   "name"
    t.integer  "vendor_id"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "icon_updated_at"
  end

  add_index "brands", ["vendor_id"], :name => "index_brands_on_vendor_id"

  create_table "imports", :force => true do |t|
    t.string   "datatype"
    t.integer  "processed"
    t.string   "csv_file_name"
    t.string   "csv_content_type"
    t.integer  "csv_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mws_response_id"
  end

  add_index "mws_order_items", ["amazon_order_id"], :name => "index_mws_order_items_on_amazon_order_id"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shipment_service_level_category"
    t.string   "name"
    t.integer  "store_id"
  end

  add_index "mws_orders", ["amazon_order_id"], :name => "index_mws_orders_on_amazon_order_id"
  add_index "mws_orders", ["mws_response_id"], :name => "index_mws_orders_on_mws_response_id"
  add_index "mws_orders", ["store_id"], :name => "index_mws_orders_on_store_id"

  create_table "mws_requests", :force => true do |t|
    t.string   "amazon_request_id"
    t.string   "request_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "store_id"
    t.integer  "mws_request_id"
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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mws_responses", ["amazon_order_id"], :name => "index_mws_responses_on_amazon_order_id"
  add_index "mws_responses", ["mws_request_id"], :name => "index_mws_responses_on_mws_request_id"

  create_table "omx_requests", :force => true do |t|
    t.string   "request_type"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "error_data"
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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["brand_id"], :name => "index_products_on_brand_id"

  create_table "stores", :force => true do |t|
    t.string   "name"
    t.string   "store_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_results_per_page"
    t.integer  "max_order_pages"
    t.string   "queue_flag"
    t.string   "verify_flag"
  end

  create_table "variant_images", :force => true do |t|
    t.integer  "variant_id"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.string   "image_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "image_updated_at"
  end

  add_index "variant_images", ["variant_id"], :name => "index_variant_images_on_variant_id"

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
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "variants", ["product_id"], :name => "index_variants_on_product_id"

  create_table "vendors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
