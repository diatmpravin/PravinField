require 'spec_helper'

describe "sku_patterns/index" do
  before(:each) do
    assign(:sku_patterns, [
      stub_model(SkuPattern,
        :brand_id => 1,
        :pattern => "Pattern",
        :condition => "Condition",
        :granularity => "Granularity",
        :priority => 1.5
      ),
      stub_model(SkuPattern,
        :brand_id => 1,
        :pattern => "Pattern",
        :condition => "Condition",
        :granularity => "Granularity",
        :priority => 1.5
      )
    ])
  end

  it "renders a list of sku_patterns" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Pattern".to_s, :count => 2
    assert_select "tr>td", :text => "Condition".to_s, :count => 2
    assert_select "tr>td", :text => "Granularity".to_s, :count => 2
    assert_select "tr>td", :text => 1.5.to_s, :count => 2
  end
end
