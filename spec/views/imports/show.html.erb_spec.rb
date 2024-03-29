require 'spec_helper'

describe "imports/show" do
  before(:each) do
    @import = assign(:import, stub_model(Import,
      :format => "Format",
      :status => "Status"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Format/)
    rendered.should match(/Status/)
  end
end
