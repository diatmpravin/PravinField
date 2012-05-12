class BrandsController < ApplicationController
  
  skip_around_filter :shopify_session

	def by_name    
    if params[:name]
    	@brand = Brand.find_by_name(params[:name])
    end
    respond_to do |format|
    	if @brand
      	format.html { redirect_to @brand }
      	format.json { render json: @brand }
      else
      	format.html { redirect_to brands_path }
      	format.json { render :status => 404, :json => {:error => 'not found'} }
      end
		end
	end
    
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
  # GET /brands?name=xxxx
  # GET /brands/1.json
  def show
    #if params[:name]
    #	@brand = Brand.find_by_name(params[:name])
    #else    
    	@brand = Brand.find(params[:id])
    #end

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
      format.html { redirect_to brands_path }
      format.json { head :ok }
    end
  end
  
end
