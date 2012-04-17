require 'test_helper'

class OmxRequestsControllerTest < ActionController::TestCase
  setup do
    @omx_request = FactoryGirl.create(:omx_request)
    @omx_response = FactoryGirl.create(:omx_response, :omx_request => @omx_request )
    @u = FactoryGirl.create(:user)
    sign_in :user, @u
  end

  test "should show omx_request" do
    get :show, id: @omx_request.to_param
    assert_response :success
  end

end
