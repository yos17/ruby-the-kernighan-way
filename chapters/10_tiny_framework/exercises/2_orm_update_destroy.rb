# Exercise 2 — Model.update(id, attrs) and Model.destroy(id)
#
# update: find the record, merge the new attrs into its @attrs, return the record.
# destroy: find the record, remove it from records, return true.
# Both should raise if the id doesn't exist.

class Model
  class << self
    attr_accessor :records, :next_id

    def inherited(subclass)
      subclass.records = []
      subclass.next_id = 1
    end

    def create(attrs)
      record = new(attrs.merge(id: next_id))
      records << record
      self.next_id += 1
      record
    end

    def find(id)
      records.find { |r| r[:id] == id } or raise "no #{name} with id #{id}"
    end

    # TODO: def update(id, attrs)
    # TODO: def destroy(id)
  end

  def initialize(attrs); @attrs = attrs; end
  def [](key); @attrs[key]; end

  # TODO: def update(attrs)  — instance method that mutates @attrs
end
