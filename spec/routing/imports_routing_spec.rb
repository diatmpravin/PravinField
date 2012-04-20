require "spec_helper"

describe ImportsController do
  describe "routing" do

    it "routes to #index" do
      get("/imports").should route_to("imports#index")
    end

    it "routes to #new" do
      get("/imports/new").should route_to("imports#new")
    end

    it "routes to #show" do
      get("/imports/1").should route_to("imports#show", :id => "1")
    end

    it "routes to #create" do
      post("/imports").should route_to("imports#create")
    end

  end
end
