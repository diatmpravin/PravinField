require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @store = FactoryGirl.create(:store, :store_type=>'Shopify')
    @vendor = FactoryGirl.create(:vendor)
    @brand = FactoryGirl.create(:brand, :vendor => @vendor)
    @brand2 = FactoryGirl.create(:brand, :vendor => @vendor)
    @product = FactoryGirl.create(:product, :brand => @brand, :name=>'Carrera 127/S')
    @product2 = FactoryGirl.create(:product, :brand => @brand, :name=>'Carrera 127/S')
    @product3 = FactoryGirl.create(:product, :brand => @brand2, :name=>'Carrera 128/S')
    @product4 = FactoryGirl.build(:product)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    # basic function, should be 3 products
    get :index
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 3

    get :index, :search => 'Carrera 127/S'
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 2    

    # only 2 products are for the given brand
    get :index, :brand_id => @brand.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 2
        
    # 3 products across 2 brands for this vendor
    get :index, :vendor_id => @vendor.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 3
    
    @brand.add_listings(@store)    

    pending "number of products returned per store depends on fixing relation between product and store"
    # only 2 products are for same store
    get :index, :store_id => @store.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 2

    # 2 products for this combination of brand and store
    get :index, :brand_id => @brand.id, :store_id => @store.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select '.product', 2

    @brand.remove_listings(@store)
  end

	test "should get specific product if sku and brand_id are passed" do
		get :index, :sku => @product.sku, :brand_id => @product.brand_id
		assert_redirected_to @product
	end

	test "should get by_sku_and_brand_id" do
		get :by_sku_and_brand_id, :sku => @product.sku, :brand_id => @product.brand_id
		assert_redirected_to @product

		get :by_sku_and_brand_id, { :sku => @product.sku, :brand_id => @product.brand_id, :format => :json }
		p = JSON.parse(@response.body)
		assert_equal @product.name, p['']['name']
	end

	test "by_sku_and_brand_id should revert to index if no match" do
		get :by_sku_and_brand_id
		assert_redirected_to products_url
		
		get :by_sku_and_brand_id, { :sku => 'different_sku', :brand_id => @product.brand_id, :format => :json }
		p = ActiveSupport::JSON.decode @response.body
		assert_equal 'not found', p['error']
	end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product" do
    assert_difference('Product.count') do
      post :create, product: @product4.attributes
    end

    assert_redirected_to product_path(assigns(:product))
  end

  test "should show product" do
    get :show, id: @product.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product.to_param
    assert_response :success
  end

  test "should update product" do
    put :update, id: @product.to_param, product: @product.attributes
    assert_redirected_to product_path(assigns(:product))
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product.to_param
    end

    assert_redirected_to products_path
  end
end
