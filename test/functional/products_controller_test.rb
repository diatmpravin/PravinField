require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @store = FactoryGirl.create(:store)
    @vendor = FactoryGirl.create(:vendor)
    @brand = FactoryGirl.create(:brand, :vendor => @vendor)
    @brand2 = FactoryGirl.create(:brand, :vendor => @vendor)
    @product = FactoryGirl.create(:product, :brand => @brand)
    @product2 = FactoryGirl.create(:product, :brand => @brand)
    @product3 = FactoryGirl.create(:product, :brand => @brand2)
    @product4 = FactoryGirl.build(:product)
    @ps = FactoryGirl.create(:products_store, :product => @product, :store => @store)
    @ps2 = FactoryGirl.create(:products_store, :product => @product3, :store => @store)
  end

  test "should get index" do
    # basic function, should be 3 products
    get :index
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select 'div.product', 3
    
    # only 2 products are for same store
    get :index, :store_id => @store.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select 'div.product', 2
    
    # only 2 products are for the given brand
    get :index, :brand_id => @brand.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select 'div.product', 2
    
    # only 1 product for this combination of brand and store
    get :index, :brand_id => @brand.id, :store_id => @store.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select 'div.product', 1
    
    # 3 products across 2 brands for this vendor
    get :index, :vendor_id => @vendor.id
    assert_response :success
    assert_not_nil assigns(:products)
    assert_select 'div.product', 3
  end

	test "should get specific product if base_sku and brand_id are passed" do
		get :index, :base_sku => @product.base_sku, :brand_id => @product.brand_id
		assert_redirected_to @product
	end

	test "should get by_base_sku_and_brand_id" do
		get :by_base_sku_and_brand_id, :base_sku => @product.base_sku, :brand_id => @product.brand_id
		assert_redirected_to @product

		get :by_base_sku_and_brand_id, { :base_sku => @product.base_sku, :brand_id => @product.brand_id, :format => :json }
		p = JSON.parse(@response.body)
		assert_equal @product.name, p['']['name']
	end

	test "by_base_sku_and_brand_id should revert to index if no match" do
		get :by_base_sku_and_brand_id
		assert_redirected_to products_url
		
		get :by_base_sku_and_brand_id, { :base_sku => 'different_sku', :brand_id => @product.brand_id, :format => :json }
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
