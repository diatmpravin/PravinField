require 'csv'

class ImportsController < ApplicationController

  #skip_before_filter :authenticate_user!

  def index
    @imports = Import.all

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

  def edit
    @import = Import.find(params[:id])
  end

  def create
    @import = Import.new(params[:import])

    respond_to do |format|
      if @import.save
        format.html { redirect_to @import, notice: 'Import was successfully created.' }
        format.json { render json: @import, status: :created, location: @import }
      else
        format.html { render action: "new" }
        format.json { render json: @import.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @import = Import.find(params[:id])

    respond_to do |format|
      if @import.update_attributes(params[:import])
        format.html { redirect_to @import, notice: 'Import was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @import.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @import = Import.find(params[:id])
    @import.destroy

    respond_to do |format|
      format.html { redirect_to imports_url }
      format.json { head :no_content }
    end
  end

 
  def importProductFile 
  	if request.post? && params[:file].present?
  		infile = params[:file].read 		  		
      n, errs = 0, []
			parentRows = 0
      CSV.parse(infile) do |row|
        n += 1        
        header = Import.importHeader(row) if n == 1               	                                     
        next if n == 1 or row.join.blank? # SKIP: header i.e. first row OR blank row
        @importproduct, @custError, @variant, @subvariant = Import.build_from_csv(parentRows,row) # build_from_csv method will map customer attributes & build new customer record
        #next if !@importproduct.blank?
        #raise @importproduct.errors.inspect
        #if !@variant.blank?
        #	raise @variant.valid?.inspect
        #	raise "create varant"
        #end
        
        #if !@subvariant.blank?
        #	raise @subvariant.inspect
        #	raise "create subvarant"
        #end
        
        #if n == 3
        #raise "Maisa"
        #end
        parentRows +=1   
        #next if !@importproduct.blank?              
        if @importproduct.valid? || (!@variant.blank? && @variant.valid?) || (!@subvariant.blank? && @subvariant.valid?) # Save upon valid otherwise collect error records to export
          #raise "valid"
          @importproduct.save                     
          @variant.save if !@variant.blank?          		
          @subvariant.save if !@subvariant.blank?          
          #raise "Maisa"      
        else
        	#raise "invalid"        	
        	row.push @importproduct.errors.full_messages.join(',')
        	row.push @custError if !@custError.blank?
          errs << row
        end
      end
      
      #Export Error file for later upload upon correction
      if errs.any?      	
        errFile ="errors_#{Date.today.strftime('%d%b%y')}.csv"
        errs.insert(0, Import.csv_header)
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
