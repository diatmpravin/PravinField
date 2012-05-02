class ProductsController < ApplicationController

	skip_around_filter :shopify_session

	def by_sku_and_brand_id    
    if params[:sku] && params[:brand_id]
    	@product = Product.find_by_sku_and_brand_id(params[:sku], params[:brand_id])
    end
    respond_to do |format|
    	if @product
      	format.html { redirect_to @product }
      	format.json { render json: @product }
      else
      	format.html { redirect_to products_url }
      	format.json { render :status => 404, :json => {:error => 'not found'} }
      end
		end
	end
  
  # GET /products
  # GET /products.json
  def index
  	@tags = Product.tag_counts_on(:tags)
  	prod_per_page = 400		
		if params[:search]
    	@products = Product.search(params[:search]).order('sku').page(params[:page]).per(prod_per_page)
    	@search = params[:search]
		elsif params[:sku] && params[:brand_id]
			@product = Product.find_by_brand_id_and_sku(params[:brand_id], params[:sku])
    elsif params[:brand_id] && params[:store_id]    	
    	@brand = Brand.find(params[:brand_id])
    	@store = Store.find(params[:store_id])
    	@products = @store.products.where(:brand_id => params[:brand_id]).page(params[:page]).per(prod_per_page)
    	@title = "#{@brand.name} Brand, #{@store.name} Store"    	
    elsif params[:brand_id]
			@brand = Brand.find(params[:brand_id])
    	@products = Product.where(:brand_id => params[:brand_id]).page(params[:page]).per(prod_per_page)
    	@title = "#{@brand.name} Brand, All Stores"
    elsif params[:store_id]
    	@store = Store.find(params[:store_id])
    	@products = @store.products.page(params[:page]).per(prod_per_page)
    	@title = "All Brands, #{@store.name} Store"
    elsif params[:vendor_id]
    	@vendor = Vendor.find(params[:vendor_id])
    	@products = @vendor.products.page(params[:page]).per(prod_per_page)
    	@title = "All #{@vendor.name} Brands, All Stores"
    else
    	@products = Product.page(params[:page]).per(prod_per_page)
    	@title = "All Brands, All Stores"
    end
    
    respond_to do |format|
    	if @product
     		format.html { redirect_to @product }
     		format.json { render json: @product }
     	else
      	format.html # index.html.erb
      	format.json { render json: @products }
      end
    end
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @product = Product.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @product }
    end
  end

  # GET /products/new
  # GET /products/new.json
  def new
    @product = Product.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @product }
    end
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(params[:product])
		@product.tag_list = params[:tags]
		
    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render json: @product, status: :created, location: @product }
      else
        format.html { render action: "new" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /products/1
  # PUT /products/1.json
  def update
    @product = Product.find(params[:id])
		@product.tag_list = params[:tags]
		
    respond_to do |format|
      if @product.update_attributes(params[:product])
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product = Product.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product and variants were successfully destroyed.' }
      format.json { head :ok }
    end
  end

end
