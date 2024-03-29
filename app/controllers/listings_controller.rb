class ListingsController < ApplicationController
  # GET /listings
  # GET /listings.json
  def index
	  if params[:mws_request_id]
		  @listings = [Listing.find_by_mws_request_id(params[:mws_request_id])].flatten
		else
		  @listings = Listing.all
		end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @listings }
    end
  end

  # GET /listings/1
  # GET /listings/1.json
  def show
    @listing = Listing.find(params[:id])
    @store = @listing.store
    @product = @listing.product

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @listing }
    end
  end

  #TODO don't need new
  # GET /listings/new
  # GET /listings/new.json
  def new
    @listing = Listing.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @listing }
    end
  end

  # GET /listings/1/edit
  def edit
    @listing = Listing.find(params[:id])
  end

  # POST /listings
  # POST /listings.json
  def create
    @listing = Listing.new(params[:listing])


    respond_to do |format|
      if @listing.save
        flash[:notice] = "Product successfully queued in #{@listing.store.name}"
        format.html { redirect_to @listing }
        format.js
        format.json { render json: @listing, status: :created, location: @listing }
      else
        if !@listing.store.nil?
          flash[:error] = "Product is already queued in #{@listing.store.name}"
        else
          flash[:error] = "Error adding product to queue"
        end
        format.html { render action: "new" }
        format.js
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /listings/1
  # PUT /listings/1.json
  def update
    @listing = Listing.find(params[:id])

    respond_to do |format|
      if @listing.update_attributes(params[:listing])
        format.html { redirect_to @listing, notice: 'Listing was successfully updated.' }
        format.js { redirect_to @listing, notice: 'Listing was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listings/1
  # DELETE /listings/1.json
  def destroy
    @listing = Listing.find(params[:id])
    @listing.destroy

    respond_to do |format|
      format.html { redirect_to listings_url }
      format.json { head :no_content }
    end
  end
end
