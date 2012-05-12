require 'spec_helper'

describe "listings/index" do
  before(:each) do
    @p = FactoryGirl.create(:product)
    @p2 = FactoryGirl.create(:product)
    @s = FactoryGirl.create(:store, :store_type=>'Shopify')
    assign(:listings, [
      stub_model(Listing, :product_id => @p.id, :store_id=>1, :operation_type=>'Update', :status=>'queued'),
      stub_model(Listing, :product_id => @p2.id, :store_id=>1, :operation_type=>'Update', :status=>'queued')
    ])
  end

  it "renders a list of listings" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
