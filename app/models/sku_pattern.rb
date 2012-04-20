class SkuPattern < ActiveRecord::Base
  attr_accessible :brand_id, :condition, :granularity, :pattern, :priority
  belongs_to :brand
  
  # accepts an object, and a variables hash
  # 1) object is used to get to a brand
  # 2) iterate over sku_patterns associated with that brand
  # 3) for each pattern and condition, for each hash key, globally substitute the hash value
  # 4) eval the resulting string to get a rendered sku, and add this to the array of skus
  # 5) if a hash key 'sku' was given, add this to the array of skus
  # 6) return the unique elements from the array of skues
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
