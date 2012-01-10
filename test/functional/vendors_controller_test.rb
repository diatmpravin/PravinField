require 'test_helper'

class VendorsControllerTest < ActionController::TestCase
  setup do
    @vendor = Factory(:vendor)
    @vendor2 = Factory.build(:vendor)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:vendors)
  end
  
  test "should redirect to specific vendor if name passed" do
    get :index, :name => @vendor.name
    assert_redirected_to @vendor
  end
  
  test "should get by_name" do
  	get :by_name, :name => @vendor.name
  	assert_redirected_to @vendor
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create vendor" do
    assert_difference('Vendor.count') do
      post :create, vendor: @vendor2.attributes
    end

    assert_redirected_to vendor_path(assigns(:vendor))
  end

  test "should show vendor" do
    get :show, id: @vendor.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @vendor.to_param
    assert_response :success
  end

  test "should update vendor" do
    put :update, id: @vendor.to_param, vendor: @vendor.attributes
    assert_redirected_to vendor_path(assigns(:vendor))
  end

  test "should destroy vendor" do
    assert_difference('Vendor.count', -1) do
      delete :destroy, id: @vendor.to_param
    end

    assert_redirected_to vendors_path
  end
end
