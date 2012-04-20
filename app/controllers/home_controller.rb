#require 'mechanize'
#require 'RubyOmx'

class HomeController < ApplicationController
  
  def welcome  	
    current_host = "#{request.host}#{':' + request.port.to_s if request.port != 80}"
    @callback_url = "http://#{current_host}/login/finalize"
    #@callback_url = "http://localhost:3000/"
  end
  
  def index    
		# get 3 products    
    #@products = ShopifyAPI::Product.find(:all, :params => {:limit => 3})
		@products = nil

    # get latest 3 orders
    @orders = nil
    #@orders   = ShopifyAPI::Order.find(:all, :params => {:limit => 3, :order => "created_at DESC" })
  end
	
end
