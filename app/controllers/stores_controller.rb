class StoresController < ApplicationController
	
  # GET /stores
  # GET /stores.json
  def index
    @stores = Store.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @stores }
    end
  end

  # GET /stores/1
  # GET /stores/1.json
  def show
    @store = Store.find(params[:id])
    @products = @store.products.length
    @order_requests = @store.order_requests.page(params[:page]).per(10)
    @feed_requests = @store.feed_requests.page(params[:page]).per(10)
    @dirty_products = @store.get_dirty_products.length
    @error_products = @store.error_products.length
    @queued_products = @store.queued_products.length

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @store }
    end
  end

  # GET /stores/new
  # GET /stores/new.json
  def new
    @store = Store.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @store }
    end
  end

  # GET /stores/1/edit
  def edit
    @store = Store.find(params[:id])
  end

  # POST /stores
  # POST /stores.json
  def create
    @store = Store.new(params[:store])

    respond_to do |format|
      if @store.save
        format.html { redirect_to @store, notice: 'Store was successfully created.' }
        format.json { render json: @store, status: :created, location: @store }
      else
        format.html { render action: "new" }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /stores/1
  # PUT /stores/1.json
  def update
    @store = Store.find(params[:id])

    respond_to do |format|
      if @store.update_attributes(params[:store])
        format.html { redirect_to @store, notice: 'Store was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stores/1
  # DELETE /stores/1.json
  def destroy
    @store = Store.find(params[:id])
    @store.destroy

    respond_to do |format|
      format.html { redirect_to stores_url }
      format.json { head :ok }
    end
  end
  
  # POST /stores/1/sync
  def sync
    @store = Store.find(params[:id])
    if @store.sync_listings
      flash[:notice] = 'Sync successfully initiated'
    else
      flash[:notice] = 'No queued products to sync'
    end
    redirect_to store_path(@store)
  end
  
  # POST /stores/1/queue
  def queue
    @store = Store.find(params[:id])
    if @store.queue_products
      flash[:notice] = 'Products successfully queued'
    else
      flash[:notice] = 'No modified products to queue'
    end
    redirect_to store_path(@store)
  end
  
end
