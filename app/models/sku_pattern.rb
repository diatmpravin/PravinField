class SkuPattern < ActiveRecord::Base
  attr_accessible :brand_id, :condition, :granularity, :pattern, :priority, :delimiter
  belongs_to :brand
  validates_presence_of :pattern, :delimiter, :granularity, :brand_id
  before_save :assign_priority
  
  ACCEPT_VARS = ['brand', 'product_sku', 'product_sku2', 'variant_sku', 'sku', 'sub_variant_sku', 'color1_code', 'color1', 'color2_code', 'color2', 'size_code', 'size', 'variant_size']

  # Parse a sku according to the SKU Patterns, but also add a variant_sku item to the hash
  def self.parse_variant(brand, sku, product_sku=nil)
    h = SkuPattern.parse(brand, sku, product_sku)
    if h.nil?
      return nil
    end
    sp = brand.sku_patterns.where(:granularity=>'Variant').order('priority').first
    if !sp.nil?
      variant_sku = sp.evaluate(h.merge({:product_sku=>product_sku}))
      return h.merge({:variant_sku=>variant_sku})
    end
    return h
  end
  
  # Work through each of the SKU Patterns associated with this brand
  # For the highest priority pattern where the variable count matches the token count for the split sku, return a key-value hash
  def self.parse(brand, sku, product_sku = nil)
    brand.sku_patterns.order('priority').each do |sp|
      h = sp.parse(sku, product_sku)
      return h if !h.nil?
    end
    return nil
  end
    
  # evaluate all sku patterns for a given brand and granularity
  # accepts an object
  # 1) object is used to get to a brand
  # 2) iterate over sku_patterns associated with that brand of the same granularity as the object given
  # 3) for each pattern and condition, for each hash key, globally substitute the hash value
  # 4) eval the resulting string to get a rendered sku, and add this to the array of skus
  # 5) if a hash key 'sku' was given, add this to the array of skus
  # 6) return the unique elements from the array of skus
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
      s.gsub!("{#{k.to_s}}", "'#{v}'") if !s.nil?
      c.gsub!("{#{k.to_s}}", "'#{v}'") if !c.nil?
    }
    
    if c.nil? || c=='' || (eval c)
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
      a << z.to_sym if ACCEPT_VARS.include?(z)
    end
    return a
  end
  
  
  # 1) Extracts the variables from this SKU Pattern
  # 2) Splits the given sku string using standard delimeter characters
  # 3) If these arrays are of equal length (assumes the sequence is the same), return them zipped together as a hash
  # 4) If not, return nil
  
  # accepts a sku and an optional product_sku
  # returns the sku split, but only up to the maximum number of delimeters seen in the pattern
  # if product_sku is given, it will not be returned as it is already known
  def parse(sku, product_sku = nil)
    keys = self.extract_vars
    pattern = self.pattern
    sku = SkuPattern.strip_amazon_suffix(sku)
    
    d = Regexp.new(eval("/[#{self.delimiter}]/"))
    
    #puts keys.to_s
    if !product_sku.nil? && keys.include?(:product_sku)
      product_sku_index = keys.index(:product_sku)
      keys.slice!(product_sku_index)
      #keys.shift
      #puts "sku: #{sku}"
      #puts "product_sku: #{product_sku}"
      #puts "pattern: #{pattern}"
      #puts "new keys: " + keys.to_s
      
      pattern_pieces = pattern.split(/\+/)
      #puts "pattern pieces: " + pattern_pieces.to_s     
      
      product_sku_rendered = eval(pattern_pieces.slice!(product_sku_index).sub(/{product_sku}/,"'#{product_sku}'"))
      #puts "product_sku_rendered: #{product_sku_rendered}"

      replace_str = product_sku_rendered
      replace_str += pattern_pieces.slice!(product_sku_index).match(d).to_s if (pattern_pieces[product_sku_index] =~ d && product_sku_index==0)
      sku.gsub!(Regexp.new(eval('/'+replace_str+'/')), '') # remove this rendered product sku from the list
      #puts "revised sku: #{sku}"
      
      pattern = pattern_pieces.join('+')
      #puts "revised pattern: #{pattern}"
    end
    

    tokens_in_pattern = pattern.split(d).length # example when delimiters might not be the same as the number of variables, if two are smashed together
    #puts "token in pattern: " + tokens_in_pattern.to_s
    
    vals = sku.split(d,tokens_in_pattern)
    #puts "split sku vals: " + vals.to_s    
    return Hash[*keys.zip(vals).flatten] if (keys.length == vals.length) # return a hash of these values
    return nil    
  end

  def self.strip_amazon_suffix(sku)
    sku.sub(/-AZ.*$/,'')
  end
 
  protected
  
  # In the absence of an explicitly assigned priority, auto generate a priority based on granularity and creation order
  def assign_priority
    if self.priority.nil?
      if self.granularity=='SubVariant'
        self.priority = 1.0
      elsif self.granularity== 'Variant'
        self.priority = 2.0
      elsif self.granularity=='Product'
        self.priority = 3.0
      end
      self.priority += SkuPattern.where(:brand_id=>self.brand_id, :granularity=>self.granularity).count / 10.0
    end
  end
    
end
