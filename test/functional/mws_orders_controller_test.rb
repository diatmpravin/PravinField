require 'test_helper'

class MwsOrdersControllerTest < ActionController::TestCase
  setup do
    @store = FactoryGirl.create(:store, :name => 'FieldDay')
    @mws_order = FactoryGirl.create(:mws_order, :store => @store)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mws_orders)
  end

  test "should get index for search" do
    get :index, :search=>'search'
    assert_response :success
    assert_not_nil assigns(:mws_orders)
  end
  
  test "should get index for unmatched" do
    get :index, :unmatched=>'1'
    assert_response :success
    assert_not_nil assigns(:mws_orders)    
  end

  test "should show mws_order" do
    get :show, id: @mws_order.to_param
    assert_response :success
  end

  test "should update mws_order" do
    put :update, id: @mws_order.to_param
    assert_redirected_to mws_order_path(assigns(:mws_order))
  end
  
end
