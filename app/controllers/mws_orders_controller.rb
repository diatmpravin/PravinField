require 'csv'

class MwsOrdersController < ApplicationController
	
  # GET /mws_orders
  # GET /mws_orders.json
  def index
    if params[:search]
    	@mws_orders = MwsOrder.search(params[:search]).page(params[:page]).per(100)
    	@search = params[:search]
    elsif params[:unmatched]
    	@mws_orders = MwsOrder.get_unmatched_skus.page(params[:page]).per(100)
    elsif params[:mws_response_id]
      @mws_orders = MwsResponse.find(params[:mws_response_id]).mws_orders.page(params[:page]).per(100)
    else
    	@mws_orders = MwsOrder.page(params[:page]).per(100)
    end

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
  
  def export_to_csv
  	if params[:startDate]
  		@orders = MwsOrder.where(:purchase_date => (params[:startDate].to_date)..(params[:endDate].to_date) ) 
  	else
  		@orders = MwsOrder.find(:all)
  	end  	
  	filename ="order_#{Date.today.strftime('%d%b%y')}"
		csv_string = CSV.generate do |csv| 
		  # header row 
		  csv << [
		  	"id",
		  	"amazon_order_id",
		  	"seller_order_id",
		  	"purchase_date",
		  	"last_update_date",
		  	"order_status",
		  	"fulfillment_channel",
		  	"sales_channel",
		  	"order_channel",
		  	"ship_service_level",
		  	"amount",
		  	"currency_code",
		  	"address_line_1",
		  	"address_line_2",
		  	"address_line_3",
		  	"city",
		  	"county",
		  	"district",
		  	"state_or_region",
		  	"postal_code",
		  	"phone",
		  	"number_of_items_shipped",
		  	"number_of_items_unshipped",
		  	"marketplace_id",
		  	"buyer_name",
		  	"buyer_email",
		  	"mws_response_id",
		  	"created_at",
		  	"updated_at",
		  	"shipment_service_level_category",
		  	"name",
		  	"store_id"
		  	] 
	 
		  # data rows 
		 @orders.each do |order| 
		    csv << [
		    	order.id,
		  		order.amazon_order_id,
		  		order.seller_order_id,
		  		order.purchase_date,
		  		order.last_update_date,
		  		order.order_status,
		  		order.fulfillment_channel,
		  		order.sales_channel,
		  		order.order_channel,
		  		order.ship_service_level,
		  		order.amount,
		  		order.currency_code,
		  		order.address_line_1,
		  		order.address_line_2,
		  		order.address_line_3,
		  		order.city,
		  		order.county,
		  		order.district,
		  		order.state_or_region,
		  		order.postal_code,
		  		order.phone,
		  		order.number_of_items_shipped,
		  		order.number_of_items_unshipped,
		  		order.marketplace_id,
		  		order.buyer_name,
		  		order.buyer_email,
		  		order.mws_response_id,
		  		order.created_at,
		  		order.updated_at,
		  		order.shipment_service_level_category,
		  		order.name,
		  		order.store_id
		    	] 
		  end 
		end 
	 
		send_data csv_string, 
		          :type => 'text/csv; charset=iso-8859-1; header=present', 
		          :disposition => "attachment; filename=#{filename}.csv" 
		
		flash[:notice] = "Export complete!"
    
  end
		

end
