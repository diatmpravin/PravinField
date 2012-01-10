class BrandsController < ApplicationController
  
  skip_around_filter :shopify_session
    
  # GET /brands
  # GET /brands.json
  def index
    @brands = Brand.all
    if params[:name]
    	@brand = Brand.find_by_name(params[:name])
    end

    respond_to do |format|
    	if @brand
    		format.html { redirect_to @brand }
    		format.json { render json: @brand }
    	else
	      format.html # index.html.erb
      	format.json { render json: @brands }
      end
    end
  end

  # GET /brands/1
  # GET /brands/1.json
  def show
    @brand = Brand.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @brand }
    end
  end

  # GET /brands/new
  # GET /brands/new.json
  def new
    @brand = Brand.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @brand }
    end
  end

  # GET /brands/1/edit
  def edit
    @brand = Brand.find(params[:id])
  end

  # POST /brands
  # POST /brands.json
  def create
    @brand = Brand.new(params[:brand])

    respond_to do |format|
      if @brand.save
        format.html { redirect_to brands_path, notice: 'Brand was successfully created.' }
        format.json { render json: @brand, status: :created, location: @brand }
      else
        format.html { render action: "new" }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /brands/1
  # PUT /brands/1.json
  def update
    @brand = Brand.find(params[:id])

    respond_to do |format|
      if @brand.update_attributes(params[:brand])
        format.html { redirect_to brands_path, notice: 'Brand was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /brands/1
  # DELETE /brands/1.json
  def destroy
    @brand = Brand.find(params[:id])
    @brand.destroy

    respond_to do |format|
      format.html { redirect_to brands_url }
      format.json { head :ok }
    end
  end
  
  # add_to_store_brand PUT   /brands/:id/add_to_store(.:format)
  def add_to_store
  	@brand = Brand.find(params[:id])
  	@store = Store.find(params[:store_id])

    respond_to do |format|
      if @brand.add_to_store(@store)
        format.html { redirect_to brands_path, notice: 'Brand successfully added to store.' }
        format.json { head :ok }
      else
        format.html { redirect_to brands_path, notice: "Error adding brand to store: #{@brand.errors}."  }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end  	
  end
  
  # remove_from_store_brand PUT   /brands/:id/remove_from_store(.:format)
  def remove_from_store
  	@brand = Brand.find(params[:id])
  	@store = Store.find(params[:store_id])

    respond_to do |format|
      if @brand.remove_from_store(@store)
        format.html { redirect_to brands_path, notice: 'Brand successfully removed from store.' }
        format.json { head :ok }
      else
        format.html { redirect_to brands_path, notice: "Error removing brand from store: #{@brand.errors}." }
        format.json { render json: @brand.errors, status: :unprocessable_entity }
      end
    end  	
  end
end
