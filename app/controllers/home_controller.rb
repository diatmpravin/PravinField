require 'mechanize'
require 'RubyOmx'

class HomeController < ApplicationController
  
  around_filter :shopify_session, :except => ['welcome']
  
  def welcome
    current_host = "#{request.host}#{':' + request.port.to_s if request.port != 80}"
    @callback_url = "http://#{current_host}/login/finalize"   
  end
  
  def index    
    #puts 'The URL should be:  ' + ShopifyAPI::Base.site.to_s
    # ShopifyAPI::Base.site = "https://04b6a9a830b55a658e6ccafa26f8e4ac:ba4b5399210d11843a6ae70592fbd4e4@fieldday.myshopify.com/admin"

		# get 3 products    
    @products = ShopifyAPI::Product.find(:all, :params => {:limit => 3})

    # get latest 3 orders
    @orders   = ShopifyAPI::Order.find(:all, :params => {:limit => 3, :order => "created_at DESC" })
  
  end
	
end