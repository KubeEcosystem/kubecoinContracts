//// Deposit business logic functions

use aiken/transaction.{Output, InlineDatum}
use aiken/list
use deposit/types.{DepositDatum, BankDatum} as deposit_types

pub fn get_deposit_outputs(outputs: List<Output>) -> List<(Output, DepositDatum)> {
  outputs
  |> list.filter_map(fn (o) {
    when o.datum is {
      InlineDatum(inline) -> {
        expect datum: DepositDatum = inline
        Some((o, datum))
      }
      _ -> None
    }
  })
}

pub fn get_bank_outputs(outputs: List<Output>) -> List<(Output, BankDatum)> {
  outputs
  |> list.filter_map(fn (o) {
    when o.datum is {
      InlineDatum(inline) -> {
        expect datum: BankDatum = inline
        Some((o, datum))
      }
      _ -> None
    }
  })
}