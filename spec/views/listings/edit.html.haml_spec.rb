require 'spec_helper'

describe "listings/edit" do
  before(:each) do
    @listing = assign(:listing, stub_model(Listing, :product_id => 1, :store_id=>1, :operation_type=>'Update', :status=>'queued'))
  end

  it "renders the edit listing form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => listings_path(@listing), :method => "post" do
    end
  end
end
