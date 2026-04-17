# Solution to Exercise 3
module MassAssign
  def assign(hash)
    hash.each { |k, v| public_send("#{k}=", v) }
    self
  end
end

if __FILE__ == $PROGRAM_NAME
  class User
    include MassAssign
    attr_accessor :name, :email
  end

  u = User.new
  u.assign(name: "Yosia", email: "y@example.com")
  puts u.name
  puts u.email
end
