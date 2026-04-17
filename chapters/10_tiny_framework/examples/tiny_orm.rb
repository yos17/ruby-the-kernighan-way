# tiny_orm.rb — a baby Active Record using method_missing for queries
# Usage: ruby tiny_orm.rb (demo)

class Model
  class << self
    attr_accessor :records, :next_id

    # Give each subclass its own record store and id counter.
    def inherited(subclass)
      subclass.records = []
      subclass.next_id = 1
    end

    # Create one record, assign it an id, and store it in memory.
    def create(attrs)
      record = new(attrs.merge(id: next_id))
      records << record
      self.next_id += 1
      record
    end

    # Return a copy of the full in-memory table.
    def all = records.dup

    # Find one record by id or raise if it does not exist.
    def find(id)
      records.find { |r| r[:id] == id } or raise "no #{name} with id #{id}"
    end

    # Return every record whose attributes match the given hash.
    def where(attrs)
      records.select { |r| attrs.all? { |k, v| r[k] == v } }
    end

    # Support dynamic finders like find_by_name("Alice").
    def method_missing(name, *args)
      if name.to_s.start_with?("find_by_")
        attr = name.to_s.delete_prefix("find_by_").to_sym
        records.find { |r| r[attr] == args.first }
      else
        super
      end
    end

    # Tell Ruby that the dynamic finders above are valid method names.
    def respond_to_missing?(name, include_private = false)
      name.to_s.start_with?("find_by_") || super
    end
  end

  # Store one record's attributes in a hash.
  def initialize(attrs)
    @attrs = attrs
  end

  # Read one attribute by key, hash-style.
  def [](key) = @attrs[key]

  # Return a copy of the underlying attribute hash.
  def to_h    = @attrs.dup

  # Show the model name and attributes in inspection output.
  def inspect = "#<#{self.class.name} #{@attrs.inspect}>"
end

if __FILE__ == $PROGRAM_NAME
  class User < Model
  end

  User.create(name: "Yosia", role: "admin")
  User.create(name: "Alice", role: "user")
  User.create(name: "Bob",   role: "user")

  p User.all.length
  p User.where(role: "user").length
  p User.find_by_name("Alice")
  p User.find(1)
end
