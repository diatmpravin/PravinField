class MwsOrderItem < ActiveRecord::Base
	belongs_to :mws_order
	belongs_to :mws_response
	belongs_to :product
	belongs_to :variant
	belongs_to :sub_variant
	
	validates_uniqueness_of :amazon_order_item_id
	validates_presence_of :mws_order_id
	validates_presence_of :clean_sku
	validates :item_price, :item_tax, :promotion_discount, :shipping_price, :shipping_tax, :shipping_discount, :gift_price, :gift_tax, :numericality => { :only_integer => false, :greater_than_or_equal_to => 0 }
	validates :quantity_ordered, :quantity_shipped, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }

	before_validation :save_clean_sku, :zero_missing_numbers
	before_save :save_catalog_match

	# searches order items BUT returns an ActiveRecord association of the mws_orders associated with the matched mws_order_items
	def self.search(search)
		fields = [ 'asin', 'clean_sku', 'title'] 
		select("mws_order_id").where(MwsHelper::search_helper(fields, search)).group('mws_order_id').collect { |oi| oi.mws_order_id }
	end
		
	def set_shipped
		self.quantity_shipped = self.quantity_ordered
		self.save
	end

	def is_gift?
		if !self.gift_message_text.nil? || !self.gift_wrap_level.nil? 
			return 1
		else
			return 0
		end
	end
	
	# Return the price per unit including tax, net of promotion discounts
	def get_item_price_per_unit
		if self.quantity_ordered.nil? || self.quantity_ordered == 0
			return 0
		else
			return self.get_item_price / self.quantity_ordered
		end
	end

	def get_item_price
		total = 0
		total += self.item_price ? self.item_price : 0 
		total += self.item_tax ? self.item_tax : 0
		total -= self.promotion_discount ? self.promotion_discount : 0
		return total
	end

	def get_ship_price
		total = 0
		total += self.shipping_price ? self.shipping_price : 0
		total += self.shipping_tax ? self.shipping_tax : 0
		total -= self.shipping_discount ? self.shipping_discount : 0
		return total
	end

	def get_gift_price
		total = 0
		total += self.gift_price ? self.gift_price : 0
		total += self.gift_tax ? self.gift_tax : 0
		return total
	end
	
	def get_total_price
		total = self.get_item_price + self.get_ship_price + self.get_gift_price
		return total
	end

	def get_price_subtotal
		total = 0
		total += self.item_price ? self.item_price : 0
		total += self.shipping_price ? self.shipping_price : 0
		total += self.gift_price ? self.gift_price : 0
		return total
	end

	def get_discount_subtotal
		total = 0
		total += self.promotion_discount ? self.promotion_discount : 0
		total += self.shipping_discount ? self.shipping_discount : 0
		return total
	end

	def get_tax_subtotal
		total = 0
		total += self.item_tax ? self.item_tax : 0
		total += self.shipping_tax ? self.shipping_tax : 0
		total += self.gift_tax ? self.gift_tax : 0
		return total		
	end
	
#	def get_omx_info
#		omx_connection = RubyOmx::Base.new(
#			"http_biz_id" => 'KbmCrvnukGKUosDSTVhWbhrYBlggjNYxGqsujuglguAJhXeKBYDdpwyiRcywvmiUrpHilblPqKgiPAOIfxOfvFOmZLUiNuIfeDrKJxvjeeblkhphUhgPixbvaCJADgIfaDjHWFHXePIFchOjQciNRdrephpJFEfGoUaSFAOcjHmhfgZidlmUsCBdXgmmxIBKhgRjxjJaTcrnCgSkghRWvRwjZgVeVvhHqALceQpdJLphwDlfFXgIHYjCGjCiwZW',
#			"udi_auth_token" => '7509fd470db4004809083c0048ef983102d6325b27730421704c1b0899109ab51de58e4dfd80acff062f8042360b5ae01ed4851f50a5d5fe38a10e81c0471a089f20799ddf11c81cc541a10a014fe04e190aee6049efdf97699096bd79db0a9fd04ca90b2a90f63925c223d236fbe97b047c104b900b7e1010fbb39453e0920'
#		)
#		response = omx_connection.get_item_info(:raw_xml => 0, :item_code => self.clean_sku)
#		return response
#	end	

	def self.get_unmatched_skus
		MwsOrderItem.select("mws_order_id").where(:product_id=>nil).group('mws_order_id')
	end

	def self.refresh_all_sku_mappings
		MwsOrderItem.all.each do |oi|
			oi.save
		end
	end

	# returns either a product, variant, or sub_variant depending on what is available
	protected
	def save_catalog_match
		x = get_catalog_match
		if x.class.to_s == 'Product'
			self.product_id = x.id
		elsif x.class.to_s == 'Variant'
			self.variant_id = x.id
			self.product_id = x.product.id
		elsif x.class.to_s == 'SubVariant'
			self.sub_variant_id = x.id
			self.variant_id = x.variant.id
			self.product_id = x.product.id
		end
	end

	def get_catalog_match
		x = SubVariant.find_by_sku(self.clean_sku)
		return x if !x.nil?
		x = Variant.find_by_sku(self.clean_sku)
		return x if !x.nil?
		x = Product.find_by_sku(self.clean_sku)
		return x if !x.nil?
		return SkuMapping.get_catalog_match(self.clean_sku)
	end

	def save_clean_sku
		if !self.seller_sku.nil?
			self.clean_sku = SkuPattern.strip_amazon_suffix(self.seller_sku)
		end
	end

	def zero_missing_numbers
		numbers = [:item_price, :item_tax, :promotion_discount, :shipping_price, :shipping_tax, :shipping_discount, :gift_price, :gift_tax, :quantity_ordered, :quantity_shipped]
		numbers.each do |n|
			if self[n].nil?
				self[n] = 0
			end
		end
	end
	
end