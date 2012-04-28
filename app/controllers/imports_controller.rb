require 'csv'

class ImportsController < ApplicationController

  def index  	
    @imports = Import.order('import_date')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @imports }
    end
  end

  def show
    @import = Import.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @import }
    end
  end

  def new
    @import = Import.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @import }
    end
  end

  def create
    @import = Import.new(params[:import])

    respond_to do |format|
      if @import.save
        @import.process_input_file
        format.html { redirect_to @import, notice: 'Import was successfully created.' }
        format.json { render json: @import, status: :created, location: @import }
      else
        format.html { render action: "new" }
        format.json { render json: @import.errors, status: :unprocessable_entity }
      end
    end
  end

end
