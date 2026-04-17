# Solution to Exercise 3
class BankAccount
  attr_reader :owner, :balance, :history

  def initialize(owner, initial_balance = 0)
    @owner   = owner
    @balance = initial_balance
    @history = []
    @frozen  = false
  end

  def deposit(amount)
    check_frozen!
    raise ArgumentError, "amount must be positive" if amount <= 0
    @balance += amount
    record(:deposit, amount)
    self
  end

  def withdraw(amount)
    check_frozen!
    raise ArgumentError, "amount must be positive" if amount <= 0
    raise "insufficient funds" if amount > @balance
    @balance -= amount
    record(:withdraw, amount)
    self
  end

  def transfer_to(other, amount)
    withdraw(amount)
    other.deposit(amount)
    self
  end

  def freeze_account!
    @frozen = true
    self
  end

  def frozen_account? = @frozen

  private

  def check_frozen!
    raise "account is frozen" if @frozen
  end

  def record(type, amount)
    @history << [type, amount, Time.now]
  end
end

if __FILE__ == $PROGRAM_NAME
  a = BankAccount.new("Yosia", 100)
  a.deposit(50)
  a.withdraw(20)
  puts a.balance     # 130
  puts a.history.length  # 2

  b = BankAccount.new("Friend")
  a.transfer_to(b, 30)
  puts a.balance     # 100
  puts b.balance     # 30

  a.freeze_account!
  begin
    a.deposit(10)
  rescue => e
    puts "error: #{e.message}"   # account is frozen
  end
end
