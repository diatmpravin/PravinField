require 'spec_helper'

describe "sku_patterns/show" do
  before(:each) do
    b = FactoryGirl.create(:brand, :name=>'Oakley')    
    @sku_pattern = assign(:sku_pattern, stub_model(SkuPattern,
      :brand_id => b.id,
      :pattern => "Pattern",
      :condition => "Condition",
      :granularity => "Granularity",
      :priority => 1,
      :delimiter => '-'
    ))
  end

  it "renders attributes in <p>" do
    render
    rendered.should match(/Oakley/)
    rendered.should match(/Pattern/)
    rendered.should match(/Condition/)
    rendered.should match(/Granularity/)
    rendered.should match(/1/)
    rendered.should match(/-/)
  end
end
