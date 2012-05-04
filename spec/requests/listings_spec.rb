require 'spec_helper'

describe "Listings" do
  
  describe "GET /listings" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get listings_path
      response.status.should be(302) # 302 redirect expected as login is required
    end
  end
end
