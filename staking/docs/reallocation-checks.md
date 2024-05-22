## DepositFix: checks for incorrect reallocation

staker_in + bank_in = deposit_out + staker_out + bank_out

Checks: 
- bank_in into deposit_out: Bank party affected
- bank_in into staker_out: Bank party affected

1. 2 + 8 = 8 + 1 + 1
2. 2 + 8 = 1 + 8 + 1

### 1

staker_fraction = 2-1=1
bank_fraction = 8-1=7
interest = fn(staker_fraction) = fn(1) = small value

Checks:
- (+): staker_fraction > 0,
- (+): deposit_amount == staker_fraction + bank_fraction, 8=1+7
- (-): bank_fraction <= interest, 7<=small value [fail]

### 2

staker_fraction = 2-8=-6
bank_fraction = 8-1=7
interest = fn(staker_fraction) = fn(-6) = negative value

Checks:
- (-): staker_fraction > 0, -6 > 0 [fail]
- (+): deposit_amount == staker_fraction + bank_fraction, 1=-6+7
- (-): bank_fraction <= interest, 7 <= negative [fail]
