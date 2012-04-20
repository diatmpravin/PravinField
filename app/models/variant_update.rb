class VariantUpdate < ActiveRecord::Base
  belongs_to :import
  belongs_to :variant
end
