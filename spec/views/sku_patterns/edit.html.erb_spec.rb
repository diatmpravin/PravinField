require 'spec_helper'

describe "sku_patterns/edit" do
  before(:each) do
    @sku_pattern = assign(:sku_pattern, stub_model(SkuPattern,
      :brand_id => 1,
      :pattern => "MyString",
      :condition => "MyString",
      :granularity => "MyString",
      :priority => 1.5
    ))
  end

  it "renders the edit sku_pattern form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => sku_patterns_path(@sku_pattern), :method => "post" do
      assert_select "select#sku_pattern_brand_id", :name => "sku_pattern[brand_id]"
      assert_select "input#sku_pattern_pattern", :name => "sku_pattern[pattern]"
      assert_select "input#sku_pattern_condition", :name => "sku_pattern[condition]"
      assert_select "select#sku_pattern_granularity", :name => "sku_pattern[granularity]"
      assert_select "input#sku_pattern_priority", :name => "sku_pattern[priority]"
    end
  end
end
