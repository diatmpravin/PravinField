class MwsOrderItemsController < ApplicationController

  # GET /mws_order_items/1
  # GET /mws_order_items/1.json
  def show
    @mws_order_item = MwsOrderItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mws_order_item }
    end
  end
  
end
