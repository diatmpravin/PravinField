require 'csv'

class ImportProductsController < ApplicationController
  # GET /import_products
  # GET /import_products.json
  def index
    @import_products = ImportProduct.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @import_products }
    end
  end

  # GET /import_products/1
  # GET /import_products/1.json
  def show
    @import_product = ImportProduct.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @import_product }
    end
  end

  # GET /import_products/new
  # GET /import_products/new.json
  def new
    @import_product = ImportProduct.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @import_product }
    end
  end

  # GET /import_products/1/edit
  def edit
    @import_product = ImportProduct.find(params[:id])
  end

  # POST /import_products
  # POST /import_products.json
  def create
    @import_product = ImportProduct.new(params[:import_product])

    respond_to do |format|
      if @import_product.save
        format.html { redirect_to @import_product, notice: 'Import product was successfully created.' }
        format.json { render json: @import_product, status: :created, location: @import_product }
      else
        format.html { render action: "new" }
        format.json { render json: @import_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /import_products/1
  # PUT /import_products/1.json
  def update
    @import_product = ImportProduct.find(params[:id])

    respond_to do |format|
      if @import_product.update_attributes(params[:import_product])
        format.html { redirect_to @import_product, notice: 'Import product was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @import_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /import_products/1
  # DELETE /import_products/1.json
  def destroy
    @import_product = ImportProduct.find(params[:id])
    @import_product.destroy

    respond_to do |format|
      format.html { redirect_to import_products_url }
      format.json { head :ok }
    end
  end
  
  def importProductFile 
  	if request.post? && params[:file].present?
  		infile = params[:file].read 		  		
      n, errs = 0, []

      CSV.parse(infile) do |row|
        n += 1                       
        next if n == 1 or row.join.blank? # SKIP: header i.e. first row OR blank row
        @importproduct = ImportProduct.build_from_csv(row) # build_from_csv method will map customer attributes & build new customer record                
        if @importproduct.valid? # Save upon valid otherwise collect error records to export
          @importproduct.save
        else        	
        	row.push @importproduct.errors.full_messages.join(',')
         errs << row
        end
      end
      
       #Export Error file for later upload upon correction
      if errs.any?      	
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, ImportProduct.csv_header)
        errCSV = CSV.generate do |csv|
          errs.each {|row| csv << row}
        end
        
        send_data errCSV, :type => 'text/csv; charset=iso-8859-1; header=present',:disposition => "attachment; filename=#{errFile}.csv"
        if @importproduct.errors == true
        	redirect_to products_path, :notice=>"Errors: #{@importproduct.errors}" and return
        end
      else
        redirect_to products_path, :notice=>'Import successful'
      end
    end
  end
  
end
