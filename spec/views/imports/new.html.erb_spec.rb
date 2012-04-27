require 'spec_helper'

describe "imports/new" do
  before(:each) do
    assign(:import, stub_model(Import).as_new_record)
  end

  it "renders new import form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => imports_path, :method => "post" do
      assert_select "input#import_input_file", :name => "import[input_file]"
      assert_select "input#import_import_date", :name => "import[import_date]"
    end
  end
end
