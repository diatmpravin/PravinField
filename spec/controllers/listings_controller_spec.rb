require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe ListingsController do

  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in :user, @user
  end

  # This should return the minimal set of attributes required to create a valid
  # Listing. As you add validations to Listing, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    @s = FactoryGirl.create(:store, :store_type=>'Shopify')
    @p = FactoryGirl.create(:product)
    { :store_id => @s.id, :product_id => @p.id}
  end

  describe "GET index" do
    it "assigns all listings as @listings" do
      listing = Listing.create! valid_attributes
      get :index, {}
      assigns(:listings).should eq([listing])
    end
  end

  describe "GET show" do
    it "assigns the requested listing as @listing" do
      listing = Listing.create! valid_attributes
      get :show, {:id => listing.to_param}
      assigns(:listing).should eq(listing)
    end
  end

  describe "GET new" do
    it "assigns a new listing as @listing" do
      get :new, {}
      assigns(:listing).should be_a_new(Listing)
    end
  end

  describe "GET edit" do
    it "assigns the requested listing as @listing" do
      listing = Listing.create! valid_attributes
      get :edit, {:id => listing.to_param}
      assigns(:listing).should eq(listing)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Listing" do
        expect {
          post :create, {:listing => valid_attributes}
        }.to change(Listing, :count).by(1)
      end

      it "assigns a newly created listing as @listing" do
        post :create, {:listing => valid_attributes}
        assigns(:listing).should be_a(Listing)
        assigns(:listing).should be_persisted
      end

      it "redirects to the created listing" do
        post :create, {:listing => valid_attributes}
        response.should redirect_to(Listing.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved listing as @listing" do
        # Trigger the behavior that occurs when invalid params are submitted
        Listing.any_instance.stub(:save).and_return(false)
        post :create, {:listing => {}}
        assigns(:listing).should be_a_new(Listing)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Listing.any_instance.stub(:save).and_return(false)
        post :create, {:listing => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested listing" do
        listing = Listing.create! valid_attributes
        # Assuming there are no other listings in the database, this
        # specifies that the Listing created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Listing.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => listing.to_param, :listing => {'these' => 'params'}}
      end

      it "assigns the requested listing as @listing" do
        listing = Listing.create! valid_attributes
        put :update, {:id => listing.to_param, :listing => valid_attributes}
        assigns(:listing).should eq(listing)
      end

      it "redirects to the listing" do
        listing = Listing.create! valid_attributes
        put :update, {:id => listing.to_param, :listing => valid_attributes}
        response.should redirect_to(listing)
      end
    end

    describe "with invalid params" do
      it "assigns the listing as @listing" do
        listing = Listing.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Listing.any_instance.stub(:save).and_return(false)
        put :update, {:id => listing.to_param, :listing => {}}
        assigns(:listing).should eq(listing)
      end

      it "re-renders the 'edit' template" do
        listing = Listing.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Listing.any_instance.stub(:save).and_return(false)
        put :update, {:id => listing.to_param, :listing => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested listing" do
      listing = Listing.create! valid_attributes
      expect {
        delete :destroy, {:id => listing.to_param}
      }.to change(Listing, :count).by(-1)
    end

    it "redirects to the listings list" do
      listing = Listing.create! valid_attributes
      delete :destroy, {:id => listing.to_param}
      response.should redirect_to(listings_url)
    end
  end

end
