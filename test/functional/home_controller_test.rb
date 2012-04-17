require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  setup do
    @u = FactoryGirl.create(:user)
    sign_in :user, @u    
  end

  test "should get index" do
    get :index
    assert_response :success
  end

end
