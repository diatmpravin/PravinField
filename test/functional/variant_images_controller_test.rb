require 'test_helper'

class VariantImagesControllerTest < ActionController::TestCase
  setup do
    @variant_image = FactoryGirl.create(:variant_image)
    @variant_image.unique_image_file_name = 'unique_file_name'
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:variant_images)
  end

  test "should get new" do
    get :new, variant_id: @variant_image.variant.to_param
    assert_response :success
  end

  test "should create variant_image" do
    assert_difference('VariantImage.count') do
      post :create, variant_image: @variant_image.attributes
    end

    assert_redirected_to variant_path(assigns(:variant))
  end

  test "should show variant_image" do
    get :show, id: @variant_image.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @variant_image.to_param
    assert_response :success
  end

  test "should update variant_image" do
    put :update, id: @variant_image.to_param, variant_image: @variant_image.attributes
    assert_redirected_to variant_image_path(assigns(:variant))
  end

  test "should destroy variant_image" do
    assert_difference('VariantImage.count', -1) do
      delete :destroy, id: @variant_image.to_param
    end

    assert_redirected_to variant_path(@variant_image.variant)
  end
end
