require 'spec_helper'

describe "listings/show" do
  before(:each) do
    @listing = assign(:listing, stub_model(Listing, :product_id => 1, :store_id=>1, :operation_type=>'Update', :status=>'queued'))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
