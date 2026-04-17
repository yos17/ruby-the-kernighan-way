# Exercise 3 — BankAccount with freeze protection
#
# - deposit(amount): add to balance, raise on negative amount
# - withdraw(amount): subtract from balance, raise on negative or insufficient
# - transfer_to(other, amount): atomic withdraw + deposit
# - freeze_account!: prevents further deposits/withdrawals
# - frozen_account?: returns the frozen state
# - history: list of [type, amount, timestamp]

class BankAccount
  attr_reader :owner, :balance, :history

  def initialize(owner, initial_balance = 0)
    @owner   = owner
    @balance = initial_balance
    @history = []
    @frozen  = false
  end

  # TODO: def deposit(amount)
  # TODO: def withdraw(amount)
  # TODO: def transfer_to(other, amount)
  # TODO: def freeze_account!
  # TODO: def frozen_account?
  # TODO: private record(type, amount)
end
