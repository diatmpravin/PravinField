class SkuPattern < ActiveRecord::Base
  attr_accessible :brand_id, :condition, :granularity, :pattern, :priority, :delimiter
  belongs_to :brand
  validates_presence_of :pattern, :delimiter, :granularity, :brand_id  
  
  # Work through each of the SKU Patterns associated with this brand
  # For the highest priority pattern where the variable count matches the token count for the split sku, return a key-value hash
  def self.parse(brand, sku)
    brand.sku_patterns.order('priority').each do |sp|
      h = sp.parse(sku)
      return h if !h.nil?
    end
    return nil
  end
    
  # 1) Extracts the variables from this SKU Pattern
  # 2) Splits the given sku string using standard delimeter characters
  # 3) If these arrays are of equal length (assumes the sequence is the same), return them zipped together as a hash
  # 4) If not, return nil
  def parse(sku)
    #TODO counter example of Adidas already which the first dash delimits, but subsequent dashes do not
    #TODO counter example what if there is no delimiter - they are just run together?
    keys = self.extract_vars
    vals = self.split_sku(sku)

    if keys.length == vals.length
      return Hash[*keys.zip(vals).flatten] # return a hash of these values
    end
    return nil
  end
  
  # evaluate all sku patterns for a given brand and granularity
  # accepts an object, and a variables hash
  # 1) object is used to get to a brand
  # 2) iterate over sku_patterns associated with that brand
  # 3) for each pattern and condition, for each hash key, globally substitute the hash value
  # 4) eval the resulting string to get a rendered sku, and add this to the array of skus
  # 5) if a hash key 'sku' was given, add this to the array of skus
  # 6) return the unique elements from the array of skues
  def self.evaluate(o)
    skus = []
    
    # Iterate through each sku mapping pattern
    o.brand.sku_patterns.order('priority').where(:granularity=>o.class.to_s).each do |sp|
      s = sp.evaluate(o.to_sku_hash)
      skus << s if !s.nil?
    end
    skus << o.sku.upcase if !o.sku.nil?
    
    # return array of unique skus
    skus.uniq
  end
   
  # evaluate a single sku pattern
  # accepts a hash of values, evaluates a sku pattern against this
  def evaluate(h)
    s = self.pattern
    c = self.condition
    
    h.each { |k,v| 
      s.gsub!("{#{k}}", "'#{v}'") if !s.nil?
      c.gsub!("{#{k}}", "'#{v}'") if !c.nil?
    }
      
    if c.nil? || ((eval c))
      s = (eval s)
      s = s.upcase if !s.nil?
      return s
    else  
      return nil
    end
  end
    
  # Extracts the variables (enclosed in {}) from this SKU Pattern and returns them as an array
  def extract_vars
    a = []
    x = self.pattern.split('{')
    x.each do |y|
      z = y.split('}').first
      a << z.to_sym if !z.nil?
    end
    return a
  end
  
  # accepts a sku and an array of delimiters
  # returns the sku split, but only up to the maximum number of delimeters seen in the pattern
  def split_sku(sku)
    r = Regexp.new(eval("/[#{self.delimiter}]/"))  
    tokens_in_pattern = self.pattern.split(r).count # example when delimiters might not be the same as the number of variables, if two are smashed together
    return sku.split(r,tokens_in_pattern)
  end
  
end
