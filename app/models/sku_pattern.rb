class SkuPattern < ActiveRecord::Base
  attr_accessible :brand_id, :condition, :granularity, :pattern, :priority
  belongs_to :brand
  
  # accepts an object, and a variables hash
  # returns an array of possible skus (1 for sku plus 1 for each pattern associated with the brand)
  def self.evaluate(o,h)
    skus = []
    
    # Iterate through each sku mapping pattern
    o.brand.sku_patterns.where(:granularity=>o.class.to_s).each do |sp|
      s = sp.pattern
      c = sp.condition
      
      h.each { |k,v| 
        s.gsub!("{#{k}}", "'#{v}'") if !s.nil?
        c.gsub!("{#{k}}", "'#{v}'") if !c.nil?
      }
      
      if c.nil? || ((eval c))
        s = eval s
        skus << s if !s.nil?
      end
    end
    skus << h['sku'] if !h['sku'].nil?
    
    # return array of unique skus
    skus.uniq
  end
    
end
