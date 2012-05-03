require 'test_helper'

class SubVariantsControllerTest < ActionController::TestCase
  setup do
    @sub_variant = FactoryGirl.create(:sub_variant)
    @sub_variant2 = FactoryGirl.build(:sub_variant)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sub_variants)
  end

  test "should get by_sku" do
  	get :by_sku, :sku => @sub_variant.sku
  	assert_redirected_to @sub_variant
  	
  	get :by_sku, { :sku => @sub_variant.sku, :format => :json }
  	sv = JSON.parse(@response.body)
  	assert_equal @sub_variant.sku, sv['']['sku']
  end

  test "should get new" do
    get :new, :variant_id=>@sub_variant2.variant.to_param
    assert_response :success
  end
  
	test "should get new via ajax" do
    xhr :get, :new, :variant_id => @sub_variant.variant_id
    assert_response :success
    assert_not_nil assigns(:product)
    assert_not_nil assigns(:variant)
    assert_not_nil assigns(:sub_variant)        
	end  

  test "should create sub_variant" do
    assert_difference('SubVariant.count') do
      post :create, sub_variant: @sub_variant2.attributes
    end

    assert_redirected_to sub_variant_path(assigns(:sub_variant))
  end

	test "should create sub_variant via ajax" do
		last_id = SubVariant.last.id
		assert_difference('SubVariant.count',1) do
			xhr :post, :create, sub_variant:@sub_variant2.attributes
			assert_redirected_to sub_variant_path(assigns(:sub_variant))
			assert_equal last_id+1, SubVariant.last.id
		end
	end  

  test "should show sub_variant" do
    get :show, id: @sub_variant.to_param
    assert_response :success
  end

  test "should show sub_variant via ajax" do
    xhr :get, :show, id: @sub_variant.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sub_variant.to_param
    assert_response :success
  end

  test "should update sub_variant" do
    put :update, id: @sub_variant.to_param, sub_variant: @sub_variant.attributes
    assert_redirected_to sub_variant_path(assigns(:sub_variant))
  end

	test "should update sub_variant via ajax" do
  	xhr :put, :update, id:@sub_variant.to_param, variant: @sub_variant.attributes
		assert_redirected_to sub_variant_path(assigns(:sub_variant))
	end

  test "should destroy sub_variant" do
    assert_difference('SubVariant.count', -1) do
      delete :destroy, id: @sub_variant.to_param
    end

    assert_redirected_to sub_variants_path
  end
end
