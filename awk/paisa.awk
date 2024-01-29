#!/usr/bin/awk -f
#
# paisa.awk -- a simple AWK script to manage personal finances
#
# Usage: paisa [FILE]
#
# FILE should contain lines with *tab separated* columns documenting
# transactions in the following format:
#
# YYYY/MM/DD        CREDIT        DEBIT        COMMENT        AMOUNT
#
# Each transaction consists of exchange of money between two accounts --
# the credit account where you withdraw money from (the one on the left)
# and debit account where you deposit it (the one on the right).  This
# may seem very different from the usual notion of credit/debit as seen
# in a bank account statement.  That's because the bank writes your
# account statement from the POV of the bank [1].
#
# In the end, the balances of each accounts should add up to zero -- no
# money is getting created or destroyed at any point in time.
#
# To make things simpler, each account should be categorized into one of
# the following kinds [2]:
#
#      ASSETS  The money you are holding onto -- like the money in your
#              bank.  If someone owes you money, add a new asset
#              account under the person's name.
#
#    EXPENSES  Money you have exchanged for something else e.g., food,
#              donations, travel, etc.
#
#      EQUITY  Equity (sometimes called capital) is what you have
#              acquired by right e.g., income tax returns, opening
#              balances, bank interests, etc.
#
#      INCOME  Income is a kind of equity.  The difference exits purely
#              for bookkeeping purposes.
#
# LIABILITIES  Accounts where you can borrow money from e.g., banks,
#              friends, restaurants, etc.
#
# Now, the idea is that you can use your equities, income, money
# borrowed from somewhere (liability), and either save it up as assets
# or spend it as expenses.  Thus, the accounting equation is born:
#
#       Equities + Income + Liabilities = Assets + Expenses
#
# This equality should always be maintained while doing double-entry
# accounting.  Remember -- all money has to go somewhere.
#
# [1]: http://en.wikipedia.org/wiki/Debits_and_credits#Aspects_of_transactions
# [2]: http://gnucash.org/docs/v2.4/C/gnucash-guide/basics-accounting1.html
#
# -m, 2014-01-12 00:00 IST
#

BEGIN {
  FS = "\t+"
}

/^[0-9]{4}\/[0-9]{2}\/[0-9]{2}/ {
  bal[$2] += $5
  bal[$3] -= $5
}

END {
  for (acc in bal) {
    printf("%-25s%10.2f\n", acc, bal[acc]) | "sort"
  }
}
