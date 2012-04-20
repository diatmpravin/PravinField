require 'spec_helper'

describe "sku_patterns/show" do
  before(:each) do
    @sku_pattern = assign(:sku_pattern, stub_model(SkuPattern,
      :brand_id => 1,
      :pattern => "Pattern",
      :condition => "Condition",
      :granularity => "Granularity",
      :priority => 1.5
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    rendered.should match(/Pattern/)
    rendered.should match(/Condition/)
    rendered.should match(/Granularity/)
    rendered.should match(/1.5/)
  end
end
