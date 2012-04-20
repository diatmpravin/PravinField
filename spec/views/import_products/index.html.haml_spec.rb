require 'spec_helper'

describe "import_products/index" do
  before(:each) do
    assign(:import_products, [
      stub_model(ImportProduct,
        :name => "Name",
        :description => "MyText",
        :meta_description => "MyText",
        :meta_keywords => "Meta Keywords",
        :brand_id => 1,
        :base_sku => "Base Sku",
        :category => "Category",
        :product_type => "Product Type",
        :variation_theme => "Variation Theme",
        :department => "Department",
        :amazon_template => "Amazon Template",
        :keywords => "MyText",
        :keywords => "MyText"
      ),
      stub_model(ImportProduct,
        :name => "Name",
        :description => "MyText",
        :meta_description => "MyText",
        :meta_keywords => "Meta Keywords",
        :brand_id => 1,
        :base_sku => "Base Sku",
        :category => "Category",
        :product_type => "Product Type",
        :variation_theme => "Variation Theme",
        :department => "Department",
        :amazon_template => "Amazon Template",
        :keywords => "MyText",
        :keywords => "MyText"
      )
    ])
  end

  it "renders a list of import_products" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "Meta Keywords".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => "Base Sku".to_s, :count => 2
    assert_select "tr>td", :text => "Category".to_s, :count => 2
    assert_select "tr>td", :text => "Product Type".to_s, :count => 2
    assert_select "tr>td", :text => "Variation Theme".to_s, :count => 2
    assert_select "tr>td", :text => "Department".to_s, :count => 2
    assert_select "tr>td", :text => "Amazon Template".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
