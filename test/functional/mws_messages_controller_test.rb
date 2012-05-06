require 'test_helper'

class MwsMessagesControllerTest < ActionController::TestCase
  setup do
    @s = FactoryGirl.create(:store)
    @p = FactoryGirl.create(:product)
    @r = FactoryGirl.create(:mws_request)
    @l = FactoryGirl.create(:listing, :store_id=>@s.id, :product_id=>@p.id, :mws_request_id=>@r.id)
    @mws_message = FactoryGirl.create(:mws_message, :matchable_id=>@p.id, :matchable_type=>'Product', :listing_id=>@l.id, :message=>[{ 'Product' => { 'Category' => 'Sport', 'Department' => 'Mens'}}])
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should show mws_message" do
    get :show, id: @mws_message.to_param
    assert_response :success
  end

end