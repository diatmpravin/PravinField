class VariantsController < ApplicationController

	skip_around_filter :shopify_session

	def by_sku    
    if params[:sku]
    	@variant = Variant.find_by_sku(params[:sku])
    end
    respond_to do |format|
    	if @variant
      	format.html { redirect_to @variant }
      	format.json { render json: @variant }
      else
      	format.html { redirect_to variants_url }
      	format.json { render :status => 404, :json => {:error => 'not found'} }
      end
		end
	end
	
  # GET /variants
  # GET /variants.json
  def index
    @variants = Variant.all
    if params[:sku]
    	@variant = Variant.find_by_sku(params[:sku])
    end

    respond_to do |format|
    	if @variant
      	format.html { redirect_to @variant }
      	format.json { render json: @variant }      
     	else
      	format.html # index.html.erb
      	format.json { render json: @variants }
      end
    end
  end

  # GET /variants/1
  # GET /variants/1.json
  def show
    @variant = Variant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.json { render json: @variant }
    end
  end

  # GET /variants/new
  # GET /variants/new.json
  def new
    @variant = Variant.new
    @product = Product.find(params[:product_id])
    @variant.product_id = @product.id
    @variant.sku = @variant.product.sku #TODO add delimiter from sku pattern and a sku pattern reminder
    @title = 'Add Variant'

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.json { render json: @variant }
    end
  end

  # GET /variants/1/edit
  def edit
    @variant = Variant.find(params[:id])
    @title = 'Edit Variant'
  end

  # POST /variants
  # POST /variants.json
  def create
    @variant = Variant.new(params[:variant])

    respond_to do |format|
      if @variant.save
        format.html { redirect_to @variant, notice: 'Variant was successfully created.' }
        format.js { redirect_to @variant, notice: 'Variant was successfully created.' }
        format.json { render json: @variant, status: :created, location: @variant }
      else
        format.html { render action: "new" }
        format.json { render json: @variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /variants/1
  # PUT /variants/1.json
  def update
    @variant = Variant.find(params[:id])

    respond_to do |format|
      if @variant.update_attributes(params[:variant])
        format.html { redirect_to @variant, notice: 'Variant was successfully updated.' }
        format.js { redirect_to @variant, notice: 'Variant was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /variants/1
  # DELETE /variants/1.json
  def destroy
    @variant = Variant.find(params[:id])
    @product = @variant.product
    @variant.destroy

    respond_to do |format|
      format.html { redirect_to @variant.product }
      format.js
      format.json { head :ok }
    end
  end
end
