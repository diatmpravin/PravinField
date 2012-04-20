require 'spec_helper'

describe "imports/edit" do
  before(:each) do
    @import = assign(:import, stub_model(Import,
      :format => "MyString",
      :input_file => "",
      :error_file => "",
      :status => "MyString"
    ))
  end

  it "renders the edit import form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => imports_path(@import), :method => "post" do
      assert_select "input#import_format", :name => "import[format]"
      assert_select "input#import_input_file", :name => "import[input_file]"
      assert_select "input#import_error_file", :name => "import[error_file]"
      assert_select "input#import_status", :name => "import[status]"
    end
  end
end
