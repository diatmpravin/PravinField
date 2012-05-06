class MwsMessagesController < ApplicationController
  
  # GET /mws_messages/1
  # GET /mws_messages/1.json
  def show
    @mws_message = MwsMessage.find(params[:id])
    @mws_message_xml = @mws_message.get_xml
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @mws_message }
    end
  end
  
end