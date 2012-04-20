require 'spec_helper'

describe "import_products/edit" do
  before(:each) do
    @import_product = assign(:import_product, stub_model(ImportProduct,
      :name => "MyString",
      :description => "MyText",
      :meta_description => "MyText",
      :meta_keywords => "MyString",
      :brand_id => 1,
      :base_sku => "MyString",
      :category => "MyString",
      :product_type => "MyString",
      :variation_theme => "MyString",
      :department => "MyString",
      :amazon_template => "MyString",
      :keywords => "MyText",
      :keywords => "MyText"
    ))
  end

  it "renders the edit import_product form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => import_products_path(@import_product), :method => "post" do
      assert_select "input#import_product_name", :name => "import_product[name]"
      assert_select "textarea#import_product_description", :name => "import_product[description]"
      assert_select "textarea#import_product_meta_description", :name => "import_product[meta_description]"
      assert_select "input#import_product_meta_keywords", :name => "import_product[meta_keywords]"
      assert_select "input#import_product_brand_id", :name => "import_product[brand_id]"
      assert_select "input#import_product_base_sku", :name => "import_product[base_sku]"
      assert_select "input#import_product_category", :name => "import_product[category]"
      assert_select "input#import_product_product_type", :name => "import_product[product_type]"
      assert_select "input#import_product_variation_theme", :name => "import_product[variation_theme]"
      assert_select "input#import_product_department", :name => "import_product[department]"
      assert_select "input#import_product_amazon_template", :name => "import_product[amazon_template]"
      assert_select "textarea#import_product_keywords", :name => "import_product[keywords]"
      assert_select "textarea#import_product_keywords", :name => "import_product[keywords]"
    end
  end
end
