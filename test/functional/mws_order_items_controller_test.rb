require 'test_helper'

class MwsOrderItemsControllerTest < ActionController::TestCase
  setup do
    @mws_order_item = FactoryGirl.create(:mws_order_item)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should show mws_order_item" do
    get :show, id: @mws_order_item.to_param
    assert_response :success
  end

  #test "should update mws_order_item" do
  #  put :update, id: @mws_order_item.to_param, mws_order_item: @mws_order_item.attributes
  #  assert_redirected_to mws_order_item_path(assigns(:mws_order_item))
  #end

end
