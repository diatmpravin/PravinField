class SkuPatternsController < ApplicationController
  # GET /sku_patterns
  # GET /sku_patterns.json
  def index
    @sku_patterns = SkuPattern.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sku_patterns }
    end
  end

  # GET /sku_patterns/1
  # GET /sku_patterns/1.json
  def show
    @sku_pattern = SkuPattern.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sku_pattern }
    end
  end

  # GET /sku_patterns/new
  # GET /sku_patterns/new.json
  def new
    @sku_pattern = SkuPattern.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sku_pattern }
    end
  end

  # GET /sku_patterns/1/edit
  def edit
    @sku_pattern = SkuPattern.find(params[:id])
  end

  # POST /sku_patterns
  # POST /sku_patterns.json
  def create
    @sku_pattern = SkuPattern.new(params[:sku_pattern])

    respond_to do |format|
      if @sku_pattern.save
        format.html { redirect_to @sku_pattern, notice: 'Sku pattern was successfully created.' }
        format.json { render json: @sku_pattern, status: :created, location: @sku_pattern }
      else
        format.html { render action: "new" }
        format.json { render json: @sku_pattern.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sku_patterns/1
  # PUT /sku_patterns/1.json
  def update
    @sku_pattern = SkuPattern.find(params[:id])

    respond_to do |format|
      if @sku_pattern.update_attributes(params[:sku_pattern])
        format.html { redirect_to @sku_pattern, notice: 'Sku pattern was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sku_pattern.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sku_patterns/1
  # DELETE /sku_patterns/1.json
  def destroy
    @sku_pattern = SkuPattern.find(params[:id])
    @sku_pattern.destroy

    respond_to do |format|
      format.html { redirect_to sku_patterns_url }
      format.json { head :no_content }
    end
  end
end
