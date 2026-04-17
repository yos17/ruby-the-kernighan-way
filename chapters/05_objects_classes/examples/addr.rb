# addr.rb — a tiny address book
# Usage: ruby addr.rb add NAME EMAIL
#        ruby addr.rb list
#        ruby addr.rb find QUERY

require "json"

Person = Data.define(:name, :email)

class AddressBook
  include Enumerable

  STORE = File.join(__dir__, "addr.json")

  def initialize
    @people = load
  end

  def add(person)
    @people << person
    save
    person
  end

  def find(query)
    @people.select { |p| p.name.downcase.include?(query.downcase) }
  end

  def each(&block) = @people.each(&block)

  private

  def load
    return [] unless File.exist?(STORE)
    JSON.parse(File.read(STORE)).map { |h| Person.new(name: h["name"], email: h["email"]) }
  end

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
