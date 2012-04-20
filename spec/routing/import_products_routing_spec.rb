require "spec_helper"

describe ImportProductsController do
  describe "routing" do

    it "routes to #index" do
      get("/import_products").should route_to("import_products#index")
    end

    it "routes to #new" do
      get("/import_products/new").should route_to("import_products#new")
    end

    it "routes to #show" do
      get("/import_products/1").should route_to("import_products#show", :id => "1")
    end

    it "routes to #edit" do
      get("/import_products/1/edit").should route_to("import_products#edit", :id => "1")
    end

    it "routes to #create" do
      post("/import_products").should route_to("import_products#create")
    end

    it "routes to #update" do
      put("/import_products/1").should route_to("import_products#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/import_products/1").should route_to("import_products#destroy", :id => "1")
    end

  end
end
