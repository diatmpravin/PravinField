class ApplicationController < ActionController::Base
  #around_filter :shopify_session, :except => ['welcome']
  before_filter :authenticate_user!
  protect_from_forgery 
  
  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to root_url
  end
  
end
