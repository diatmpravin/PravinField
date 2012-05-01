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

describe ImportsController do

  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in :user, @user
  end
  
  after(:each) do
    Import.all.each do |i|
      i.destroy
    end
  end

  # This should return the minimal set of attributes required to create a valid
  # Import. As you add validations to Import, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    { :import_date => '2011-10-01', :input_file=>Rack::Test::UploadedFile.new('test/fixtures/csv/2XU.txt', 'text/csv') }
  end
  
  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ImportsController. Be sure to keep this updated too.
  #def valid_session
  #  {}
  #end

  describe "GET index" do
    it "assigns all imports as @imports" do
      import = Import.create! valid_attributes
      get :index
      assigns(:imports).should eq([import])
    end
  end

  describe "GET show" do
    it "assigns the requested import as @import" do
      import = Import.create! valid_attributes
      get :show, {:id => import.to_param}
      assigns(:import).should eq(import)
    end
  end

  describe "GET new" do
    it "assigns a new import as @import" do
      get :new, {}
      assigns(:import).should be_a_new(Import)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Import" do
        
        # Add minimum brand and sku patterns to database to process test file
        b = FactoryGirl.create(:brand, :name=>'2XU')
        sp2 = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}+'-'+{size_code}", :granularity=>'SubVariant')
        sp = FactoryGirl.create(:sku_pattern, :brand_id=>b.id, :pattern=>"{product_sku}+'-'+{color1_code}", :granularity=>'Variant')
        
        expect {
          expect {
            expect {
              post :create, {:import => valid_attributes}
            }.to change(Import, :count).by(1)
          }.to change(Product, :count).by(3) # 3 products in test file
        }.to change(SubVariant, :count).by(22) # with 22 associated sub variants
      end

      it "assigns a newly created import as @import" do
        post :create, {:import => valid_attributes}
        assigns(:import).should be_a(Import)
        assigns(:import).should be_persisted
      end

      it "redirects to the created import" do
        post :create, {:import => valid_attributes}
        response.should redirect_to(Import.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved import as @import" do
        # Trigger the behavior that occurs when invalid params are submitted
        Import.any_instance.stub(:save).and_return(false)
        post :create, {:import => {}}
        assigns(:import).should be_a_new(Import)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Import.any_instance.stub(:save).and_return(false)
        post :create, {:import => {}}
        response.should render_template("new")
      end
    end
  end

end
