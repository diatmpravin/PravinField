class SubVariantsController < ApplicationController
  
  skip_around_filter :shopify_session

	def by_sku    
    if params[:sku]
    	@sub_variant = SubVariant.find_by_sku(params[:sku])
    end
    respond_to do |format|
    	if @sub_variant
      	format.html { redirect_to @sub_variant }
      	format.json { render json: @sub_variant }
      else
      	format.html { redirect_to sub_variants_url }
      	format.json { render :status => 404, :json => {:error => 'not found'} }
      end
		end
	end
  
  # GET /sub_variants
  # GET /sub_variants.json
  def index
    @sub_variants = SubVariant.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sub_variants }
    end
  end

  # GET /sub_variants/1
  # GET /sub_variants/1.json
  def show
    @sub_variant = SubVariant.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sub_variant }
    end
  end

  # GET /sub_variants/new
  # GET /sub_variants/new.json
  def new
    @sub_variant = SubVariant.new
    @variant = Variant.find(params[:variant_id])
    @sub_variant.variant_id = @variant.id
    @product = @variant.product
    @title = "Add SubVariant"  

    respond_to do |format|
      format.html # new.html.erb
      format.js
      format.json { render json: @sub_variant }
    end
  end

  # GET /sub_variants/1/edit
  def edit
    @sub_variant = SubVariant.find(params[:id])
    @title = "Edit SubVariant"
  end

  # POST /sub_variants
  # POST /sub_variants.json
  def create
    @sub_variant = SubVariant.new(params[:sub_variant])

    respond_to do |format|
      if @sub_variant.save
        format.html { redirect_to @sub_variant, notice: 'SubVariant was successfully created.' }
        format.js { redirect_to @sub_variant, notice: 'SubVariant was successfully created.' }
        format.json { render json: @sub_variant, status: :created, location: @sub_variant }
      else
        format.html { render action: "new" }
        format.json { render json: @sub_variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sub_variants/1
  # PUT /sub_variants/1.json
  def update
    @sub_variant = SubVariant.find(params[:id])

    respond_to do |format|
      if @sub_variant.update_attributes(params[:sub_variant])
        format.html { redirect_to @sub_variant, notice: 'SubVariant was successfully updated.' }
        format.js { redirect_to @sub_variant, notice: 'SubVariant was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @sub_variant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sub_variants/1
  # DELETE /sub_variants/1.json
  def destroy
    @sub_variant = SubVariant.find(params[:id])
    @sub_variant.destroy

    respond_to do |format|
      format.html { redirect_to sub_variants_url }
      format.json { head :ok }
    end
  end
end
