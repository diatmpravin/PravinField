require 'spec_helper'

describe "import_products/show" do
  before(:each) do
    @import_product = assign(:import_product, stub_model(ImportProduct,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
    rendered.should match(/Meta Keywords/)
    rendered.should match(/1/)
    rendered.should match(/Base Sku/)
    rendered.should match(/Category/)
    rendered.should match(/Product Type/)
    rendered.should match(/Variation Theme/)
    rendered.should match(/Department/)
    rendered.should match(/Amazon Template/)
    rendered.should match(/MyText/)
    rendered.should match(/MyText/)
  end
end
