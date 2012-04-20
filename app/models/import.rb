class Import < ActiveRecord::Base
  has_attached_file :input_file
  has_attached_file :error_file

  has_many :variant_updates #TODO dependent destroy won't work, updates will not be undoable

  attr_accessible :error_file, :format, :import_date, :input_file, :status
  
end
