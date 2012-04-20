class ImportProduct < ActiveRecord::Base
	
	def self.build_from_csv(row)
		data = row[0].split(';')
    cust = User.find_or_initialize_by_email(data[1])    
    cust.attributes ={:name => data[0],
      :email => data[1],
      :password => data[2]}
    return cust
  end	
  
  def self.csv_header
    "Name,Email,Password".split(',')
  end
	
end


