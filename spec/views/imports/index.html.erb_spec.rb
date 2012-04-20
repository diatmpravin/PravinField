require 'spec_helper'

describe "imports/index" do
  before(:each) do
    assign(:imports, [
      stub_model(Import,
        :format => "Format",
        :input_file => "",
        :error_file => "",
        :status => "Status"
      ),
      stub_model(Import,
        :format => "Format",
        :input_file => "",
        :error_file => "",
        :status => "Status"
      )
    ])
  end

  it "renders a list of imports" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Format".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Status".to_s, :count => 2
  end
end
