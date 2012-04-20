require 'test_helper'

class BrandsControllerTest < ActionController::TestCase

  setup do
    @brand = FactoryGirl.create(:brand)
    @brand2 = FactoryGirl.build(:brand)
    @store = FactoryGirl.create(:store, :store_type => 'Shopify')
    @product1 = FactoryGirl.create(:product, :brand => @brand)
    @product2 = FactoryGirl.create(:product, :brand => @brand)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:brands)
	end
	
	test "should redirect to specific brand if name passed" do    
    get :index, id: nil, name: @brand.name
    assert_redirected_to @brand
  end
  
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create brand" do
    assert_difference('Brand.count') do
      post :create, brand: @brand2.attributes
    end
    assert_redirected_to brands_path

    post :create, brand: @brand2.attributes
    assert_response :success # render new, not a redirect
  end

  test "should show brand" do
    get :show, id: @brand.to_param
    assert_response :success
  end

	test "should show brand by name" do    
    get :by_name, :name=>@brand.name
    assert_redirected_to @brand
    
    get :by_name, :name=>@brand.name, :format => :json
    b = JSON.parse(@response.body)
    assert_equal @brand.name, b['']['name'] #TODO why is root element blank?
    
    get :by_name, :name=>'unknown name'
    assert_redirected_to brands_path
  end

  test "should get edit" do
    get :edit, id: @brand.to_param
    assert_response :success
  end

  test "should update brand" do
    put :update, id: @brand.to_param, brand: @brand.attributes
    assert_redirected_to brands_path
    
    @brand3 = FactoryGirl.create(:brand)
    put :update, id: @brand3.to_param, brand: @brand.attributes
    assert_response :success # render edit, not a redirect
  end

  test "should destroy brand" do
    assert_difference('Brand.count', -1) do
      delete :destroy, id: @brand.to_param
    end

    assert_redirected_to brands_path
  end

  test "should add and remove brand to store" do    
    put :add_to_store, id: @brand.to_param, store_id: @store.to_param
    assert_redirected_to brands_path

    put :remove_from_store, id: @brand.to_param, store_id: @store.to_param
    assert_redirected_to brands_path
  end
  
end
