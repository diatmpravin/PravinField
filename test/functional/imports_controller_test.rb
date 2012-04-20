require 'test_helper'

class importControllerTest < ActionController::TestCase

  setup do
    @import = FactoryGirl.create(:import)
    @import2 = FactoryGirl.build(:import)
    @store = FactoryGirl.create(:store, :store_type => 'Shopify')
    @product1 = FactoryGirl.create(:product, :import => @import)
    @product2 = FactoryGirl.create(:product, :import => @import)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:imports)
	end
	  
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create import" do
    assert_difference('Brand.count') do
      post :create, import: @import2.attributes
    end

    assert_redirected_to imports_path
  end

  test "should show import" do
    get :show, id: @import.to_param
    assert_response :success
  end

end
