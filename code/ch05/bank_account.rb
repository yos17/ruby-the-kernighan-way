#!/usr/bin/env ruby
# bank_account.rb — BankAccount class demo

class BankAccount
  attr_reader :owner, :balance

  def initialize(owner, initial = 0)
    @owner   = owner
    @balance = initial.to_f
    @history = []
    @frozen  = false
  end

  def deposit(amount)
    check_active!
    raise ArgumentError, "Amount must be positive" unless amount > 0
    @balance += amount
    record("Deposit", amount)
    self
  end

  def withdraw(amount)
    check_active!
    raise ArgumentError, "Amount must be positive" unless amount > 0
    raise "Insufficient funds (balance: $#{"%.2f" % @balance})" if amount > @balance
    @balance -= amount
    record("Withdrawal", amount)
    self
  end

  def transfer_to(other, amount)
    withdraw(amount)
    other.deposit(amount)
    self
  end

  def freeze_account
    @frozen = true
    self
  end

  def statement
    puts "Account: #{@owner}"
    puts "Balance: $#{"%.2f" % @balance}"
    puts "\nHistory:"
    @history.each do |e|
      puts "  #{e[:date].strftime("%Y-%m-%d %H:%M")}  #{e[:type].ljust(12)}  $#{"%.2f" % e[:amount]}"
    end
  end

  def to_s
    "BankAccount(#{@owner}, $#{"%.2f" % @balance})"
  end

  private

  def check_active!
    raise "Account is frozen" if @frozen
  end

  def record(type, amount)
    @history << { type: type, amount: amount, date: Time.now }
  end
end

# Demo
yosia = BankAccount.new("Yosia", 1000)
bob   = BankAccount.new("Bob",   500)

yosia.deposit(250).deposit(100)
yosia.withdraw(75)
yosia.transfer_to(bob, 200)

yosia.statement
puts ""
bob.statement
