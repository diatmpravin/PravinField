require 'spec_helper'

describe "imports/new" do
  before(:each) do
    assign(:import, stub_model(Import,
      :format => "MyString",
      :status => "MyString"
    ).as_new_record)
  end

  it "renders new import form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => imports_path, :method => "post" do
      assert_select "input#import_format", :name => "import[format]"
      assert_select "input#import_status", :name => "import[status]"
    end
  end
end
