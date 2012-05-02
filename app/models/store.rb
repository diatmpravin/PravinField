require 'amazon/mws'
class Store < ActiveRecord::Base	
	has_many :mws_requests, :dependent => :destroy
	has_many :mws_orders, :dependent => :destroy
	has_many :mws_order_items, :through => :mws_orders
	has_many :listings, :dependent => :destroy
	
  has_many :queued_listings, :class_name => 'Listing', :conditions => ["listings.mws_request_id IS NULL"], :order => 'listings.id ASC'

	has_many :products, :through => :listings
	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS
	after_initialize :init_mws_connection
	
	validates_inclusion_of :store_type, :in => %w(MWS Shopify), :message => 'Invalid store type'
	validates_uniqueness_of :name, :scope => [:store_type]
	
	with_options :if => "store_type == 'MWS'" do |mws|
    mws.validates :order_results_per_page, :numericality => { :only_integer => true, :greater_than => 0, :less_than_or_equal_to => 100 }
    mws.validates :max_order_pages, :numericality => { :only_integer => true, :greater_than => 0 }
  end
  
  validates :authenticated_url, :presence => true, :if => "store_type == 'Shopify'"
	
	US_MKT = "ATVPDKIKX0DER"
	
	attr_accessor :mws_connection

	def get_orders_missing_items
		orders_array = Array.new
		self.mws_orders.each do |o|
			if o.get_item_quantity_ordered==0 || o.get_item_quantity_missing > 0
				orders_array << o
			end
		end
		return orders_array
	end

	def reprocess_orders_missing_items
		orders_array = get_orders_missing_items
		sleep_time = MwsOrder::get_sleep_time_per_order(orders_array.count)
		orders_array.each do |o|
			o.reprocess_order
			sleep sleep_time
		end
	end
  
	def init_mws_connection
		if self.name=='HDO'
			self.mws_connection = Amazon::MWS::Base.new(
				"access_key"=>"AKIAIIPPIV2ZWUHDD5HA",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A3VX72MEBB21JI",
  			"marketplace_id"=>US_MKT )
		elsif self.name=='HDO Webstore'
			self.mws_connection = Amazon::MWS::Base.new(
				"access_key"=>"AKIAJLQG3YW3XKDQVDIQ",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A3HFI0FEL8PQWZ",
  			"marketplace_id"=>"A1MY0E7E4IHPQT" )
		elsif self.name=='FieldDay'
			self.mws_connection = Amazon::MWS::Base.new(
		  	"access_key"=>"AKIAIUCCPIMBYXZOZMXQ",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A39CG4I2IXB4I2",
  			"marketplace_id"=>US_MKT )
 		else
			self.mws_connection = Amazon::MWS::Base.new(
		  	"access_key"=>"DUMMY",
  			"secret_access_key"=>"DUMMY",
  			"merchant_id"=>"DUMMY",
  			"marketplace_id"=>US_MKT )
 		end
	end

  # get recent orders (from last order downloaded to present)
	def fetch_recent_orders
	  #puts "FETCH_RECENT_ORDERS: last date is #{get_last_date}"
		fetch_orders(get_last_date, Time.now)
		#puts "FETCH_RECENT_ORDERS: finishing"
	end

  # get orders from time_from until time_to
	def fetch_orders(time_from, time_to)
	  #puts "FETCH_ORDERS"
		request = MwsRequest.create!(:request_type => "ListOrders", :store => self)
		response = self.mws_connection.get_orders_list(      
			:last_updated_after => time_from.iso8601,
			:results_per_page => self.order_results_per_page,
      :fulfillment_channel => ["MFN","AFN"],
			:order_status => ["Unshipped", "PartiallyShipped", "Shipped", "Unfulfillable"],
			:marketplace_id => [US_MKT]
		)
		#puts "FETCH_ORDERS: sent ListOrders request, response type is #{response.class.to_s}"
		#TODO this handles a single US marketplace only
		request.process_orders(self.mws_connection, response)
		#puts "FETCH_ORDERS: finishing fetch_orders"
	end

	# if there are orders, take 1 second after the most recent order was updated, otherwise shoot 3 hours back
	def get_last_date	
		latest_order = self.mws_orders.order('last_update_date DESC').first
		if !latest_order.nil?
			return latest_order.last_update_date.since(1)
		else
			return Time.now.ago(60*60*3)
		end
	end

  # takes an array of products, lists them on the appropriate storefront
	def add_listings(products=[])
		if self.store_type == 'Shopify'
			add_listings_shopify(products)
		#elsif self.store_type == 'MWS'
		#	add_listings_amazon(products)
		end
	end

  # takes an array of products, removes listings from the appropriate storefront
	def remove_listings(products)
		if self.store_type == 'Shopify'
			remove_listings_shopify(products)
		#elsif self.store_type == 'MWS'
		#	remove_listings_amazon(products)
		end
	end

  # Create an mws_request for an update operation type
  # Add queued listings to this request and prepare messages
  # Submit request (feed) to Amazon
  def sync_mws_listings(async=true)
    raise "Attempted Non MWS Store Sync To MWS" if self.store_type!='MWS'
    
    # create a new mws_request, with request_type SubmitFeed
    request = MwsRequest.create!(:store=>self, :request_type=>'SubmitFeed', :feed_type=>MwsRequest::FEED_STEPS[0], :message_type=>MwsRequest::FEED_MSGS[0])

    # Take all listings that are unsynchronized (queued for synchronization, have now mws_request_id), by order of listing creation
    m = []
    self.queued_listings.each do |l|
      l.update_attributes!(:mws_request_id => request.id)
      m += l.build_mws_messages(request)
    end
    request.update_attributes!(:message => m)    
    
    # submit the feed to Amazon for processing, store feed ID
    return request.delay.submit_mws_feed(self,async) if async
    return request.submit_mws_feed(self,async)
  end

	private
	def add_listings_shopify(products)
		return nil if self.authenticated_url.nil?

		ShopifyAPI::Base.site = self.authenticated_url
		products.each do |p|
		  shopify_product = ShopifyAPI::Product.create(p.attributes_for_shopify)
      Listing.create(:product_id=>p.to_param, :store_id=>self.id, :handle=>shopify_product.handle, :foreign_id=>shopify_product.id)
		end
	end
	
	def remove_listings_shopify(products)
	  products.each do |p|
		  l = Listing.find_by_store_id_and_product_id(self.id, p.id)
		  shopify_product = ShopifyAPI::Product.find(l.foreign_id)
		  shopify_product.destroy
		  Listing.create(:store_id=>self.id, :product_id=>p.id, :operation_type=>'Delete')
		end
	end

	#def add_listings_amazon(products)
	#  messages = []
	#	products.each do |p|
	#	  messages += p.attributes_for_amazon(:product_data)
  #    Listing.create(:product_id=>p.to_param, :store_id=>self.id)
      # listing needs to be qualified as pending, incomplete, etc
	#	end
  #  request = MwsRequest.create(:store=>self, :request_type=>'SubmitFeed', :feed_type=>:product_data, :message=>messages)    
	#end
	
	#def remove_listings_amazon(products)
	#  products.each do |p|
	#	  l = Listing.find_by_store_id_and_product_id(self.id, p.id)
  		#TODO code for remove from mws
	#	  l.inactivate
	#  end
	#end
	
end
