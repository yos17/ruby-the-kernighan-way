# Exercise 4 — Persistent tiny_orm
#
# Make Model save to JSON after every create/update/destroy.
# Each subclass declares its own file:
#
#   class User < Model
#     persist_to "users.json"
#   end
#
# On require, if users.json exists, load from it.
#
# Hints:
#   - Add a class-level attr for the persist path
#   - Override create to call save_to_disk after appending
#   - Add a class method `persist_to(path)` that sets the path AND attempts to load

require "json"

class Model
  class << self
    attr_accessor :records, :next_id, :persist_path

    def inherited(subclass)
      subclass.records = []
      subclass.next_id = 1
    end

    # TODO: def persist_to(path)
    #   self.persist_path = path
    #   load_from_disk if File.exist?(path)
    # end
    #
    # TODO: def save_to_disk; File.write(persist_path, JSON.pretty_generate(records.map(&:to_h))); end
    # TODO: def load_from_disk; ... initialize records and next_id from the file ... end
    #
    # TODO: override create to call save_to_disk if persist_path
  end
end
