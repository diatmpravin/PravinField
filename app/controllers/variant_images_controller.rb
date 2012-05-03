class VariantImagesController < ApplicationController

	skip_around_filter :shopify_session
	
  # GET /variant_images
  # GET /variant_images.json
  def index
    @variant_images = VariantImage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @variant_images }
    end
  end

  # GET /variant_images/1
  # GET /variant_images/1.json
  def show
    @variant_image = VariantImage.find(params[:id])
    @variant = @variant_image.variant

    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.json { render json: @variant_image }
    end
  end

  # GET /variant_images/new
  # GET /variant_images/new.json
  def new
    @variant_image = VariantImage.new
    @variant = Variant.find(params[:variant_id])
    @variant_image.variant_id = @variant.id
    @product = @variant.product

    respond_to do |format|
      format.html # new.html.erb
      format.js # new.js.erb
      format.json { render json: @variant_image }
    end
  end

  # GET /variant_images/1/edit
  def edit
    @variant_image = VariantImage.find(params[:id])
		@variant = @variant_image.variant
    @product = @variant.product    
  end

  # POST /variant_images
  # POST /variant_images.json
  def create
    params[:variant_image][:image2] = params[:variant_image][:image] # For image replication across two s3 accounts
    @variant_image = VariantImage.new(params[:variant_image])
		@variant = @variant_image.variant
    @product = @variant.product    

    respond_to do |format|
      if @variant_image.save
        format.html { redirect_to @variant, notice: 'Image added successfully.' }
        format.js { redirect_to @variant_image, notice: 'Image added successfully.' }
        format.json { render json: @variant_image, status: :created, location: @variant_image }
      else
        format.html { render action: "new" }
        format.js { render action: "new" }
        format.json { render json: @variant_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /variant_images/1
  # PUT /variant_images/1.json
  def update
    @variant_image = VariantImage.find(params[:id])

    respond_to do |format|
      if @variant_image.update_attributes(params[:variant_image])
        format.html { redirect_to @variant_image, notice: 'Variant image was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @variant_image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /variant_images/1
  # DELETE /variant_images/1.json
  def destroy
    @variant_image = VariantImage.find(params[:id])
    @variant = @variant_image.variant
    @variant_image.destroy

    respond_to do |format|
      format.html { redirect_to @variant.product }
      format.json { head :ok }
    end
  end
end