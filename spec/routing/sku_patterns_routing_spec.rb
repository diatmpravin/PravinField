require "spec_helper"

describe SkuPatternsController do
  describe "routing" do

    it "routes to #index" do
      get("/sku_patterns").should route_to("sku_patterns#index")
    end

    it "routes to #new" do
      get("/sku_patterns/new").should route_to("sku_patterns#new")
    end

    it "routes to #show" do
      get("/sku_patterns/1").should route_to("sku_patterns#show", :id => "1")
    end

    it "routes to #edit" do
      get("/sku_patterns/1/edit").should route_to("sku_patterns#edit", :id => "1")
    end

    it "routes to #create" do
      post("/sku_patterns").should route_to("sku_patterns#create")
    end

    it "routes to #update" do
      put("/sku_patterns/1").should route_to("sku_patterns#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/sku_patterns/1").should route_to("sku_patterns#destroy", :id => "1")
    end

  end
end
