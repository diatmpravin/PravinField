require 'test_helper'

class ProductsStoresControllerTest < ActionController::TestCase
  setup do
    @store = FactoryGirl.create(:store, :store_type => 'Shopify')
    @product = FactoryGirl.create(:product)
    @product2 = FactoryGirl.create(:product)
    @ps = FactoryGirl.build(:products_store, :store => @store, :product => @product)
    @ps2 = FactoryGirl.create(:products_store, :store => @store, :product => @product2)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should create products_store" do
    assert_difference('ProductsStore.count') do
      post :create, products_store: @ps.attributes
    end
    
    #TODO delete created product to avoid collecting too many in test store
    #assert_difference('ProductsStore.count',-1) do    
    #	delete :destroy, id: @ps.to_param
    #end
    
		#TODO assert_redirected_to product_path(assigns(:product))
  end

  test "should destroy products_store" do
    assert_difference('ProductsStore.count', -1) do
      delete :destroy, id: @ps2.to_param
    end

    assert_redirected_to products_path
  end
end
