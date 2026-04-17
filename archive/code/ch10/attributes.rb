module Attributes
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@attribute_definitions, {})
  end

  module ClassMethods
    def has_attribute(name, type: nil, default: nil, required: false)
      @attribute_definitions[name] = { type: type, default: default, required: required }
      define_method(name) { (@attributes||{})[name] || default }
      define_method("#{name}=") { |v| (@attributes||={})[name] = v }
    end
    def attribute_definitions; @attribute_definitions; end
  end

  def initialize(attrs = {})
    @attributes = {}
    attrs.each { |k,v| send("#{k}=", v) if respond_to?("#{k}=") }
  end

  def valid?
    @errors = self.class.attribute_definitions.each_with_object([]) do |(name, opts), errs|
      errs << "#{name} is required" if opts[:required] && send(name).to_s.strip.empty?
    end
    @errors.empty?
  end

  def errors; @errors || []; end
  def to_s; "#{self.class}(#{self.class.attribute_definitions.keys.map { |n| "#{n}: #{send(n).inspect}" }.join(', ')})"; end
end

class Product
  include Attributes
  has_attribute :name,  type: String, required: true
  has_attribute :price, type: Float,  default: 0.0
  has_attribute :stock, type: Integer, default: 0
end

p = Product.new(name: "Ruby Book", price: 39.99, stock: 10)
puts p
puts p.valid?

bad = Product.new(price: 9.99)
puts bad.valid?
puts bad.errors.inspect
