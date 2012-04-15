class ApplicationController < ActionController::Base
  around_filter :shopify_session, :except => ['welcome']
  protect_from_forgery 
end
