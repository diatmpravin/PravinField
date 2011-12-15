require 'amazon/mws'
require 'RubyOmx'

class Store < ActiveRecord::Base	
	has_many :mws_requests, :dependent => :destroy
	has_many :mws_orders, :dependent => :destroy
	validates_inclusion_of :store_type, :in => %w(MWS Shopify), :message => 'Invalid store type'
	validates_uniqueness_of :name, :scope => [:store_type]
	after_initialize :init_mws_connection
	
	US_MKT = "ATVPDKIKX0DER"
	MAX_FAILURE_COUNT = 2
	ORDER_FAIL_WAIT = 60
	
	@mws_connection = nil
	@cutoff_time = nil

	def get_orders_missing_items
		orders_array = Array.new
		self.mws_orders.each do |o|
			if (o.item_quantity < (o.number_of_items_unshipped + o.number_of_items_shipped))
				orders_array << o
			end
		end
		return orders_array
	end

	def reprocess_orders_with_missing_items
		orders_array = get_orders_missing_items
		orders_array.each do |o|
			o.reprocess_order
		end
	end

	def fetch_recent_orders 		
		response_id = fetch_orders
		if !response_id.nil?
			response = MwsResponse.find(response_id)	
		end
	end
	
	def get_mws_connection
		@mws_connection
	end

	private
	def init_mws_connection
		
		if self.name=="HDO"
			@mws_connection = Amazon::MWS::Base.new(
				"access_key"=>"AKIAIIPPIV2ZWUHDD5HA",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A3VX72MEBB21JI",
  			"marketplace_id"=>US_MKT
			)
		elsif self.name=="HDO Webstore"
			@mws_connection = Amazon::MWS::Base.new(
				"access_key"=>"AKIAJLQG3YW3XKDQVDIQ",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A3HFI0FEL8PQWZ",
  			"marketplace_id"=>"A1MY0E7E4IHPQT"
			)
		else
			@mws_connection = Amazon::MWS::Base.new(
		  	"access_key"=>"AKIAIUCCPIMBYXZOZMXQ",
  			"secret_access_key"=>"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",
  			"merchant_id"=>"A39CG4I2IXB4I2",
  			"marketplace_id"=>US_MKT
  		)
 		end	
	end

	def fetch_orders		

		@cutoff_time = get_last_date

		request = MwsRequest.create!(:request_type => "ListOrders", :store_id => self.id) 
		response = @mws_connection.get_orders_list(      
			:last_updated_after => @cutoff_time.iso8601,
			:results_per_page => self.order_results_per_page,
      :fulfillment_channel => ["MFN","AFN"],
			:order_status => ["Unshipped", "PartiallyShipped", "Shipped", "Unfulfillable"],
			:marketplace_id => [US_MKT]
		)
		next_token = request.process_response(@mws_connection,response,0,0)
		if next_token.is_a?(Numeric)
			return next_token
		end
		
		page_num = 1
		failure_count = 0
		while next_token.is_a?(String) && page_num<self.max_order_pages do
			response = @mws_connection.get_orders_list_by_next_token(:next_token => next_token)
			n = request.process_response(@mws_connection,response,page_num,ORDER_FAIL_WAIT)
			if n.is_a?(Numeric)
				failure_count += 1
				if failure_count >= MAX_FAILURE_COUNT
					return n
				end
			else
				page_num += 1
				next_token = n
			end
		end
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
end
