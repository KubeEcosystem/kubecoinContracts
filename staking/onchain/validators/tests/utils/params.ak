//// Deposit Params - helping fixtures for testing

use common/types.{VerificationKeyHash} as common_types
use deposit/types.{DepositDatum, DepositFixDatum} as deposit_types
use deposit/apy

pub type DepositType {
  Flexible
  Fixed
}

pub type DepositParams {
  deposit_type: DepositType,
  bank_owner: VerificationKeyHash, // Required only for Fixed deposits
  beneficiar: ByteArray,
  bank_in: Int,
  staker_in: Int,
  deposit_start: Int,
  deposit_end: Int,
  deposit_amount: Int,
}

pub fn get_deposit_datum(self: DepositParams) -> DepositDatum {
  let interest = self |> get_interest
  DepositDatum {
    beneficiar: self.beneficiar,
    deposit_start: self.deposit_start,
    fixed: when self.deposit_type is {
      Flexible -> None
      Fixed -> Some (
        DepositFixDatum {
          deposit_bank_owner: self.bank_owner,
          deposit_end: self.deposit_end,
          deposit_bank_fraction: interest
        }
      )
    }
  }
}

pub fn get_interest(self: DepositParams) -> Int {
  apy.calc_fix_interest(
    self.deposit_amount,
    self.deposit_start,
    self.deposit_end
  )
}

pub fn get_output_values(self: DepositParams) -> (Int, Int, Int) {
  let interest = self |> get_interest
  let deposit_out = self.deposit_amount + interest
  let staker_out = self.staker_in - self.deposit_amount
  let bank_out = self.bank_in - interest
  (deposit_out, staker_out, bank_out)
}
