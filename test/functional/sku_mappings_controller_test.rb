require 'test_helper'

class SkuMappingsControllerTest < ActionController::TestCase
  setup do
    @sku_mapping = FactoryGirl.create(:sku_mapping)
    @sku_mapping2 = FactoryGirl.build(:sku_mapping)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sku_mappings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sku_mapping" do
    assert_difference('SkuMapping.count') do
      post :create, sku_mapping: @sku_mapping2.attributes
    end

    assert_redirected_to sku_mapping_path(assigns(:sku_mapping))
  end

  test "should show sku_mapping" do
    get :show, id: @sku_mapping.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sku_mapping.to_param
    assert_response :success
  end

  test "should update sku_mapping" do
    put :update, id: @sku_mapping.to_param, sku_mapping: @sku_mapping.attributes
    assert_redirected_to sku_mapping_path(assigns(:sku_mapping))
  end

  test "should destroy sku_mapping" do
    assert_difference('SkuMapping.count', -1) do
      delete :destroy, id: @sku_mapping.to_param
    end

    assert_redirected_to sku_mappings_path
  end
end
