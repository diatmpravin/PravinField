require 'spec_helper'

describe "listings/new" do
  before(:each) do
    assign(:listing, stub_model(Listing, :product_id => 1, :store_id=>1, :operation_type=>'Update', :status=>'queued').as_new_record)
  end

  it "renders new listing form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => listings_path, :method => "post" do
    end
  end
end
