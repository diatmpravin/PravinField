class MwsOrdersController < ApplicationController

  # GET /mws_orders
  # GET /mws_orders.json
  def index  
    @mws_orders = MwsOrder.order('purchase_date DESC').page(params[:page]).per(100)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @mws_orders }
    end
  end

  # GET /mws_orders/1
  # GET /mws_orders/1.json
  def show
    @mws_order = MwsOrder.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mws_order }
    end
  end

  # PUT /mws_orders/1
  # PUT /mws_orders/1.json
  def update
    @mws_order = MwsOrder.find(params[:id])
    
		message = ''
		response = @mws_order.reprocess_order
		if response.is_a?(Numeric)
			r = MwsResponse.find(response)
			message += "response_id #{r.id} #{r.error_code}: #{r.error_message}"
		end

    respond_to do |format|
    	format.html { redirect_to @mws_order, notice: "Amazon order reprocessed.  #{message}" }
      format.json { render json: @mws_order }
    end
  end

end
