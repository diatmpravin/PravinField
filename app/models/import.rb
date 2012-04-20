class Import < ActiveRecord::Base
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  validates_presence_of :import_date
  
	#def self.build_from_csv(row)
	#	data = row[0].split(';')
  #  cust = User.find_or_initialize_by_email(data[1])    
  #  cust.attributes ={:name => data[0],
  #    :email => data[1],
  #    :password => data[2]}
  #  return cust
  #end	
  
  #def self.csv_header
  #  "Name,Email,Password".split(',')
  #end  
  
end
