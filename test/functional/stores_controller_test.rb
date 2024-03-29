require 'test_helper'

class StoresControllerTest < ActionController::TestCase
  setup do
    @store = FactoryGirl.create(:store)
    @store.name = "UniqueStore"
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:stores)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create store" do
    assert_difference('Store.count') do
      post :create, store: @store.attributes
    end

    assert_redirected_to store_path(assigns(:store))
  end

  test "should show store" do
    get :show, id: @store.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @store.to_param
    assert_response :success
  end

  test "should update store" do
    put :update, id: @store.to_param, store: @store.attributes
    assert_redirected_to store_path(assigns(:store))
  end

  test "should destroy store" do
    assert_difference('Store.count', -1) do
      delete :destroy, id: @store.to_param
    end
    assert_redirected_to stores_path
  end
  
  test "should queue updated products" do
    post :queue, id: @store.to_param
	  assert_equal 'No modified products to queue', flash[:notice]    
    assert_redirected_to store_path(assigns(:store))
    
	  p1 = FactoryGirl.create(:product)
	  l1 = FactoryGirl.create(:listing, :store_id=>@store.id, :product_id=>p1.id, :built_at=>Time.now)
	  l1.update_attributes(:status=>'active')
	  p1.update_attributes(:department=>'MENS')
	  assert l1.reload.is_dirty?
	  assert_equal 1, @store.reload.get_dirty_products.length
	  
	  post :queue, id:@store.to_param
	  assert_equal 'Products successfully queued', flash[:notice]
	  assert_redirected_to store_path(assigns(:store))
	  assert_equal 0, @store.reload.get_dirty_products.length
  end
  
  test "should sync queued products" do
    assert_equal 0, @store.queued_products.length
    post :sync, id: @store.to_param
    assert_equal 'No queued products to sync', flash[:notice]
    assert_redirected_to store_path(assigns(:store))
    
	  p1 = FactoryGirl.create(:product)
	  l1 = FactoryGirl.create(:listing, :store_id=>@store.id, :product_id=>p1.id, :built_at=>Time.now)    
    assert_equal 1, @store.reload.queued_products.length
    post :sync, id: @store.to_param
    assert_equal 'Sync successfully initiated', flash[:notice]
    assert_redirected_to store_path(assigns(:store))
    assert_equal 0, @store.reload.queued_products.length
  end

  # do not use stub / mock for shopify as they provide a test store
  #test "should add listings for shopify" do
    #@store2 = FactoryGirl.create(:store, :store_type => 'Shopify')
    #@ps = FactoryGirl.build(:products_store, :store_id => @store.to_param, :product_id => @product.to_param)
    #assert_nil @ps.foreign_id

    # add product to shopify test store  
    #assert_difference('ProductsStore.count') do
    #  post :create, products_store: @ps.attributes
    #end
    
    # confirm shopify test store received product
    #assert_redirected_to @product
    #@ps = @product.reload.products_stores.first
    #assert_not_nil @ps.foreign_id
    #assert_kind_of ShopifyAPI::Product, ShopifyAPI::Product.find(@ps.foreign_id)

    # get product count including product just added
    #shopify_product_count = ShopifyAPI::Product.all.count
  
    # delete created product to avoid collecting in test store, limit 101 products
    #assert_difference('ProductsStore.count',-1) do    
    #	delete :destroy, id: @ps.to_param
    #end
    #assert_redirected_to products_path
     
    # confirm product is no longer on the store
    #assert_equal shopify_product_count-1, ShopifyAPI::Product.all.count         
  #end
  
  #test "should add listings for amazon" do
    #@store = FactoryGirl.create(:store, :store_type => 'MWS')
    #@ps = FactoryGirl.build(:products_store, :store_id => @store.to_param, :product_id => @product.to_param)
    #assert_nil @ps.foreign_id

  
  #end
  
  #test "should remove listings for amazon" do
  
  #end
  
end
