# encoding: utf-8

require 'amazon/mws'

class MwsOrder < ActiveRecord::Base
	belongs_to :mws_response
	belongs_to :store
	has_many :mws_order_items, :dependent => :destroy
	has_many :omx_requests
	has_many :omx_responses, :through => :omx_requests
	validates_uniqueness_of :amazon_order_id
	validates_presence_of :mws_response_id
	validates_presence_of :purchase_date
	validates_associated :store
	default_scope :order => 'purchase_date DESC'
	
	MAX_ORDER_ITEM_PAGES = 20
	MAX_FAILURE_COUNT = 1
	ORDER_ITEM_FAIL_WAIT = 60

	# return a list of skus that, as yet, have not been matched up to products, variants, or sub_variants
	def self.get_unmatched_skus
		where(:id => MwsOrderItem.get_unmatched_skus)
	end

	def self.search(search)
		# get sub_matches from order_items
		o1 = MwsOrderItem.search(search)

		# get direct matches at order level
		fields = [ 'amazon_order_id', 'seller_order_id', 'address_line_1', 'address_line_2', 'address_line_3', 'city', 'state_or_region', 'country_code', 'postal_code', 'buyer_name', 'buyer_email', 'shipment_service_level_category', 'name']
		bind_vars = MwsHelper::search_helper(fields, search)
		o2 = select('id').where(bind_vars).collect { |o| o.id }
			
		# combine the two arrays of IDs and remove duplicates, and return all relevant records
		where(:id => o1 | o2)
	end

	# return a value between 0 and 6 for the number of seconds to delay between OrderItem requests to Amazon
	def self.get_sleep_time_per_order(order_count)
		if order_count.is_a?(Numeric) && order_count>0
			sleep_time = 0.0
			request_buffer = 15.0
			refresh_interval = 5.0
			sleep_time = (([order_count - request_buffer, 0.0].max) / order_count)*refresh_interval
			return sleep_time
		else
			return 0
		end
	end

  # set each item in an order to shipped
	def set_shipped
		self.mws_order_items.each do |i|
			i.set_shipped
		end
	end

	def get_item_quantity_ordered
		q = 0
		q += self.number_of_items_unshipped ? self.number_of_items_unshipped : 0
		q += self.number_of_items_shipped ? self.number_of_items_shipped : 0
		return q
	end
	
	def get_item_quantity_loaded
		q = 0
		self.mws_order_items.each do |i|
			q += i.quantity_ordered
		end
		return q
	end

	def get_item_quantity_missing
		return get_item_quantity_ordered - get_item_quantity_loaded
	end
	
	def get_item_price
		total = 0
		self.mws_order_items.each do |i|
			total += i.get_item_price
		end
		return total
	end

	def get_ship_price
		total = 0
		self.mws_order_items.each do |i|
			total += i.get_ship_price
		end
		return total		
	end
	
	def get_gift_price
		total = 0
		self.mws_order_items.each do |i|
			total += i.get_gift_price
		end
		return total		
	end

	def get_total_price
		total = 0
		self.mws_order_items.each do |i|
			total += i.get_total_price
		end
		return total		
	end

	def pushed_to_omx?
		pushed = "Error"
		if self.fulfillment_channel == "AFN"
			return 'N/A'
		elsif (self.order_status != 'Unshipped' && self.order_status != 'PartiallyShipped')
			return 'Shipped'
		end
		self.omx_responses.each do |resp|
			if !resp.ordermotion_order_number.nil? && resp.ordermotion_order_number != ''
				pushed = 'Yes'
			elsif resp.error_data.nil? || resp.error_data == ''
				pushed = 'No'
			elsif !resp.error_data.match(/The provided Order ID has already been used for the provided store/).nil?
				pushed = 'Dup'
			end
		end
		return pushed
	end

	def reprocess_order
		store = self.store
		if !store.mws_connection.nil?
			return process_order(store.mws_connection)
		end 
	end

	# Process XML order into ActiveRecord, and process items on order
	def process_order(mws_connection)
	  #puts "      PROCESS_ORDER: #{self.amazon_order_id}"
		return_code = fetch_order_items(mws_connection)

		#TODO if reprocessing, use the update OMX API call rather than append
		if get_item_quantity_missing == 0 && self.fulfillment_channel == "MFN" && (self.order_status == 'Unshipped' || self.order_status == 'PartiallyShipped')
		  #puts "      PROCESS_ORDER: about to append to omx"
			append_to_omx
		else
		  #puts "      PROCESS_ORDER: not appending to omx, return code #{return_code}"		  
		end
		return return_code
	end
	
	# fetch items associated with this order
	# calls the Amazon MWS API
	def fetch_order_items(mws_connection)		
	  #puts "        FETCH_ORDER_ITEMS: for order #{self.amazon_order_id}, about to call MWS ListOrderItems"
		parent_request = self.mws_response.mws_request
		request = MwsRequest.create!(:request_type => "ListOrderItems", :store_id => parent_request.store_id, :mws_request_id => parent_request.id)
		response = mws_connection.get_list_order_items(:amazon_order_id => self.amazon_order_id)
		#puts "        FETCH_ORDER_ITEMS: called MWS ListOrderItems, about to process response"
		next_token = request.process_response(mws_connection, response,0,0)
		#puts "        FETCH_ORDER_ITEMS: back, finished process_response"
		if next_token.is_a?(Numeric)
			return next_token
		end
		
		page_num = 1
		failure_count = 0
		while next_token.is_a?(String) && page_num<MAX_ORDER_ITEM_PAGES do
		  #puts "        FETCH_ORDER_ITEMS: next_token is present, about to fetch by next token for #{self.amazon_order_id}"
			response = mws_connection.get_list_order_items_by_next_token(:next_token => next_token)
			#puts "        FETCH_ORDER_ITEMS: called MWS ListOrderItemsByNextToken, about to process response"
			n = request.process_response(mws_connection,response,page_num,ORDER_ITEM_FAIL_WAIT)
			if n.is_a?(Numeric)
				failure_count += 1
				if failure_count >= MAX_FAILURE_COUNT
					return n
				end
			else
				page_num += 1 # don't want to increment page if there is an error
				next_token = n
			end
			#puts "        FETCH_ORDER_ITEMS: finished process_response for next token"
		end
		#puts "        FETCH_ORDER_ITEMS: finishing order #{self.amazon_order_id}"
	end

	def process_order_item(item, response_id)
	  #puts "              PROCESS_ORDER_ITEM: order #{self.amazon_order_id}, item #{item.amazon_order_item_id}"
	  
		amz_item = MwsOrderItem.find_by_amazon_order_item_id(item.amazon_order_item_id)
		if amz_item.nil?
		  amz_item = MwsOrderItem.create(:amazon_order_item_id=>item.amazon_order_item_id, :seller_sku=>item.seller_sku, :mws_response_id=>response_id, :mws_order_id=>self.id, :amazon_order_id=>self.amazon_order_id)
		  #puts "              PROCESS_ORDER_ITEM: new item #{amz_item.amazon_order_item_id} created, id: #{amz_item.id}" 
		else
		  #puts "              PROCESS_ORDER_ITEM: existing item #{amz_item.amazon_order_item_id} updated, id: #{amz_item.id}"		  
		end
		amz_item.update_attributes(item.as_hash)
		#puts "              PROCESS_ORDER_ITEM: finished"
	end

	def omx_first_name
		if self.name.nil?
			return '[Blank]'
		end
		a = self.name.strip.split(/ /)
		a.slice!(a.count-1)
		first_name = a.join(" ")
		if first_name.nil? || first_name == ''
			return '[Blank]'
		else
			return first_name
		end
	end
	
	def omx_last_name
		if self.name.nil?
			return '[Blank]'
		end
		a = self.name.strip.split(/ /)
		a.last
	end
	
	def omx_shipping_method
		# Shipping Methods
		# 0	UPS Ground (1-4 Days Transit Time)	 	0.00	
		# 2	Drop-Ship Montague	1	40.00	
		# 1	UPS Free UPS Ground Shipping (US ONLY)	0	0.00	
		# 3	UPS Ground	003	0.00	
		# 4	UPS 2nd Day Air	002	0.00	
		# 5	UPS Next Day Air	001	0.00	
		# 7	UPS 3 Day Select	004	0.00	
		# 12	UPS Worldwide Expedited	008	0.00	
		# 13	UPS Worldwide Express	009	0.00	
		# 14	UPS Worldwide Express Plus	010	0.00	
		# 6	International Flat Rate via USPS Express	2	35.00
		# 8	USPS Express	 	29.99	
		# 9	USPS Priority	 	6.99	
		# 10	Int. Express USPS	 	0.00	
		# 11	Int. Priority USPS	 	0.00	
		# 15	USPS Domestic Priority Flat Rate	 	6.99	
		# 16	USPS Domestic Express Flat Rate	 	34.99	
		# 17	USPS International Global Priority	 	29.99	
		# 18	USPS International Global Express	 	39.99	
		# 19	Next Day Air (USA Only)	 	0.00	
		# 20	2nd Day Air (USA Only)	 	0.00	
		# 21	Priority Mail (Free $74.99 and above), 3-6 days 0.00	
	
		if self.shipment_service_level_category == 'Expedited'
			return 18
		elsif self.shipment_service_level_category == 'NextDay'
			return 19
		elsif self.shipment_service_level_category == 'SecondDay'
			return 20
		else
			return 9
		end
	end

  def omx_address
    a1 = self.address_line_1
		a2 = nil
		if a1.nil?
			a1 = "#{self.address_line_2} #{self.address_line_3}"
		else
			a2 = "#{self.address_line_2} #{self.address_line_3}"
		end
    return a1, a2
  end

	def omx_state
		if self.state_or_region.nil?
			return nil
		else
			state = State.find_by_raw_state(self.state_or_region.upcase)
			if state.nil?
				State.create(:raw_state => self.state_or_region, :clean_state => self.state_or_region)
				return self.state_or_region
			else
				return state.clean_state
			end
		end  
	end

	def omx_country
		if self.country_code.nil?
			return nil
		else
			country = State.find_by_raw_state(self.country_code.upcase)
			if country.nil?
				State.create(:raw_state => self.country_code, :clean_state => self.country_code)
				return self.country_code
			else
				return country.clean_state
			end
		end  
	end
	
	#TODO must deal with gift wrapping, line item by line item
	def omx_gift_wrapping
		if !omx_gift_message.nil? || !omx_gift_wrap_level.nil? 
			return 'True'
		else
			return 'False'
		end
	end

	#TODO gift message should be line by line item
	def omx_gift_wrap_level
		self.mws_order_items.each do |i| 
			if !i.gift_wrap_level.nil? && i.gift_wrap_level != ''
				return i.gift_wrap_level
			end
		end
		return nil
	end
	
	def omx_gift_message
		items = self.mws_order_items
		items.each do |i| 
			if !i.gift_message_text.nil? && i.gift_message_text != ''
				return i.gift_message_text
			end
		end
		return nil
	end

	def append_to_omx(params ={})

		omx_connection = RubyOmx::Base.new(
			"http_biz_id" => 'KbmCrvnukGKUosDSTVhWbhrYBlggjNYxGqsujuglguAJhXeKBYDdpwyiRcywvmiUrpHilblPqKgiPAOIfxOfvFOmZLUiNuIfeDrKJxvjeeblkhphUhgPixbvaCJADgIfaDjHWFHXePIFchOjQciNRdrephpJFEfGoUaSFAOcjHmhfgZidlmUsCBdXgmmxIBKhgRjxjJaTcrnCgSkghRWvRwjZgVeVvhHqALceQpdJLphwDlfFXgIHYjCGjCiwZW',
			"udi_auth_token" => '7509fd470db4004809083c0048ef983102d6325b27730421704c1b0899109ab51de58e4dfd80acff062f8042360b5ae01ed4851f50a5d5fe38a10e81c0471a089f20799ddf11c81cc541a10a014fe04e190aee6049efdf97699096bd79db0a9fd04ca90b2a90f63925c223d236fbe97b047c104b900b7e1010fbb39453e0920'
		)

		request = OmxRequest.create!(
			:mws_order_id => self.id,
			:request_type => "UDOA",
			:keycode => "AM01",
			:vendor => "",
			:store_code => "#{self.sales_channel} #{self.fulfillment_channel} #{self.mws_response.mws_request.store.name}",
			:queue_flag => self.mws_response.mws_request.store.queue_flag,
			:verify_flag => self.mws_response.mws_request.store.verify_flag
		)
		
		omx_line_items = Array.new
		omx_product_amount = 0
		omx_shipping_amount = 0
		self.mws_order_items.each do |i| 			
			omx_line_items << { :item_code => i.clean_sku, :quantity => i.quantity_ordered, :unit_price => i.get_item_price_per_unit }
			omx_product_amount += (i.get_item_price_per_unit * i.quantity_ordered)
			omx_shipping_amount += (i.get_ship_price + i.get_gift_price)
		end 
		
		address1, address2 = omx_address
		
		begin
		result = omx_connection.send_udoa_request(
			:keycode => request.keycode,
			:order_id => self.amazon_order_id,
			:order_date => self.purchase_date.to_s(:db),
			:queue_flag => request.queue_flag,
			:verify_flag => request.verify_flag,
			:bill_to => {
			  :address_type => 'BillTo',
			  :title_code => '0',
			  :firstname => self.omx_first_name,
			  :lastname => self.omx_last_name,
			  :address1 => address1,
			  :address2 => address2,
			  :city => self.city,
			  :state => omx_state,
			  :zip => self.postal_code,
			  :tld => omx_country,
  			:phone_number => self.phone,
  			:email => self.buyer_email},
			:method_code => self.omx_shipping_method,
			:shipping_amount => omx_shipping_amount,
			:gift_wrapping => omx_gift_wrapping, 
			:gift_message => omx_gift_message,
			:line_items => omx_line_items,
			:total_amount => (omx_shipping_amount + omx_product_amount),
			:store_code => request.store_code,
			:vendor => request.vendor, 
			:raw_xml => 0)
    rescue SocketError
      omx_response = OmxResponse.create!(:omx_request_id => request.id, :success => 0, :error_data => 'Not sent, SocketError #{$!} (no internet connection)')
    else
  		omx_response = OmxResponse.create!(:omx_request_id => request.id, :success => result.success)		
  		if omx_response.success != 1
  			omx_response.error_data = result.error_data.strip
  			#logger.debug "Order push was unsuccessful #{omx_response.error_data}"
  		else
  			omx_response.ordermotion_response_id = result.OMX
  			omx_response.ordermotion_order_number = result.order_number
  			#logger.debug "Success:#{result.success}, omx:#{result.OMX}, order number:#{result.order_number}"	
  		end
  		omx_response.save!      
    end

		# for raw_xml option
		 #puts response.body.to_s
		return omx_response
	end
	
end