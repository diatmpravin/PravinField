require 'amazon/mws'
class Store < ActiveRecord::Base	
	has_many :mws_requests, :dependent => :destroy
	has_many :mws_orders, :dependent => :destroy
	has_many :mws_order_items, :through => :mws_orders
	
	has_many :listings, :dependent => :destroy
  has_many :queued_listings, :class_name => 'Listing', :conditions => ["listings.status=?", 'queued'], :order => 'listings.id ASC' # order is important to processing them FIFO
	has_many :active_listings, :class_name => 'Listing', :conditions => ["listings.status=?", 'active'], :order => 'listings.built_at ASC'
	has_many :products, :through => :active_listings # Products relation only works for active listings

	has_attached_file :icon, PAPERCLIP_STORAGE_OPTIONS
	after_initialize :init_store_connection
	
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
  
	def init_store_connection
	  if self.store_type == 'MWS'
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
 		  #Amazon::MWS::Base.debug=true
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

  # takes an array of products, creates removal listings for this store
	def add_listings(products=[])
		products.collect { |p| Listing.create!(:store_id=>self.id, :product_id=>p.id, :operation_type=>'Update')}
	end

  # takes an array of products, creates removal listings for this store
	def remove_listings(products=[])
    products.collect { |p| Listing.create!(:store_id=>self.id, :product_id=>p.id, :operation_type=>'Delete')}
	end

  # Create an mws_request for an update operation type
  # Add queued listings to this request and prepare messages
  # Submit request (feed) to Amazon
  def sync_listings(async=true)
    return nil if !self.queued_listings.any?
    
    if self.store_type=='MWS'
      # create a new mws_request, with request_type SubmitFeed
      request = MwsRequest.create!(:store_id=>self.id, :request_type=>'SubmitFeed', 
                :feed_type=>MwsRequest::FEED_STEPS[0], :message_type=>MwsRequest::FEED_MSGS[0])

      # Take all listings that are unsynchronized (queued for synchronization, have now mws_request_id), by order of listing creation
      request.update_attributes!(:message => self.queued_listings.collect { |l| l.assign_amazon!(request) })
      #puts request.inspect
    
      # submit the feed to Amazon for processing, store feed ID
      return request.delay.submit_mws_feed(self,async) if async
      return request.submit_mws_feed(self,async)

    elsif self.store_type=='Shopify'

      # Create a request with SubmitShopify request type
      request = MwsRequest.create!(:store_id=>self.id, :request_type=>'SubmitShopify')
  		
  		# Process all of the listings (do not batch like with MWS)
  		self.queued_listings.each do |l| 
  		  l.delay.process_shopify!(request) if async
  		  l.process_shopify!(request) if !async
  		end

  		return request # MWS returns a response, shopify returns a request, it is inconsistent
    end
  end
	
end