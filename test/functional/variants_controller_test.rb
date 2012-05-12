require 'test_helper'

class VariantsControllerTest < ActionController::TestCase
  setup do
    @product = FactoryGirl.create(:product)
    @variant = FactoryGirl.create(:variant, :product => @product)
    @variant2 = FactoryGirl.build(:variant)
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:variants)
  end
  
  test "should redirect to specific variant if sku passed" do
  	get :index, :sku => @variant.sku
  	assert_redirected_to @variant
  end

  test "should get by_sku" do
  	get :by_sku, :sku => @variant.sku
  	assert_redirected_to @variant
  	
  	get :by_sku, { :sku => @variant.sku, :format => :json }
  	v = JSON.parse(@response.body)
  	assert_equal @variant.sku, v['']['sku']
  end

  test "by_sku should revert to index if no match" do
  	get :by_sku
  	assert_redirected_to variants_path
  	
  	get :by_sku, { :sku => 'different_sku', :format => :json }
  	v = ActiveSupport::JSON.decode @response.body
  	assert_equal 'not found', v['error']
  end

  test "should get new" do
    get :new, :product_id => @product.to_param
    assert_response :success
  end

	test "should get new via ajax" do
    xhr :get, :new, :product_id => @product.to_param
    assert_response :success
    assert_not_nil assigns(:product)
    assert_not_nil assigns(:variant)    
	end

  test "should create variant" do
    assert_difference('Variant.count') do
      post :create, variant: @variant2.attributes
    end

    assert_redirected_to variant_path(assigns(:variant))
  end

	test "should create variant via ajax" do
		last_id = Variant.last.id
		assert_difference('Variant.count',1) do
			xhr :post, :create, variant:@variant2.attributes
			assert_redirected_to variant_path(assigns(:variant))
			assert_equal last_id+1, Variant.last.id
	    #assert_select '#flashnotices'
      #assert_select_jquery :show, '#flashnotices'	
		end
	end

  test "should show variant" do
    get :show, id: @variant.to_param
    assert_response :success
  end

  test "should show variant via ajax" do
    xhr :get, :show, id: @variant.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @variant.to_param
    assert_response :success
  end

  test "should update variant" do
    put :update, id: @variant.to_param, variant: @variant.attributes
    assert_redirected_to variant_path(assigns(:variant))
  end

	test "should update variant via ajax" do
  	xhr :put, :update, id:@variant.to_param, variant: @variant.attributes
		assert_redirected_to variant_path(assigns(:variant))
	end

  test "should destroy variant" do
    assert_difference('Variant.count', -1) do
      delete :destroy, id: @variant.to_param
    end

    assert_redirected_to @variant.product
  end
  
  test "should destroy variant via AJAX" do
    assert_difference('Variant.count', -1) do
      xhr :delete, :destroy, id: @variant.to_param
    end
    assert_response :success
  end  
end
