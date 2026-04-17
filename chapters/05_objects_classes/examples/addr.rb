# addr.rb — a tiny address book
# Usage: ruby addr.rb add NAME EMAIL
#        ruby addr.rb list
#        ruby addr.rb find QUERY

require "json"

Person = Data.define(:name, :email)

class AddressBook
  include Enumerable

  STORE = File.join(__dir__, "addr.json")

  # Load any saved people so the address book persists across runs.
  def initialize
    @people = load
  end

  # Append one person, save the file, and return the person that was added.
  def add(person)
    @people << person
    save
    person
  end

  # Return every person whose name contains the query string.
  def find(query)
    @people.select { |p| p.name.downcase.include?(query.downcase) }
  end

  # Let Enumerable methods walk through the saved people.
  def each(&block) = @people.each(&block)

  private

  # Read the JSON file and turn each hash back into a Person value object.
  def load
    return [] unless File.exist?(STORE)
    JSON.parse(File.read(STORE)).map { |h| Person.new(name: h["name"], email: h["email"]) }
  end

  # Write the in-memory people back to disk as pretty JSON.
  def save
    File.write(STORE, JSON.pretty_generate(@people.map { |p| { name: p.name, email: p.email } }))
  end
end

book = AddressBook.new

case ARGV.shift
when "add"
  name, email = ARGV
  abort "usage: addr.rb add NAME EMAIL" unless name && email
  person = book.add(Person.new(name: name, email: email))
  puts "added: #{person.name} <#{person.email}>"
when "list"
  book.each { |p| puts "#{p.name}  #{p.email}" }
when "find"
  query = ARGV.first or abort "usage: addr.rb find QUERY"
  matches = book.find(query)
  matches.each { |p| puts "#{p.name}  #{p.email}" }
  puts "no matches" if matches.empty?
else
  abort "usage: addr.rb (add|list|find) ARGS..."
end
