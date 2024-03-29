class OmxRequestsController < ApplicationController

  # GET /omx_requests/1
  # GET /omx_requests/1.json
  def show
    @omx_request = OmxRequest.find(params[:id])
    @omx_response = @omx_request.omx_response

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @omx_request }
    end
  end

end
