//// DepositFix Tests

use aiken/transaction.{Spend, Transaction, ScriptContext, Input}
use aiken/transaction/credential.{Address, ScriptCredential, VerificationKeyCredential}
use aiken/cbor
use tests/utils/helpers
use deposit/types.{BankDatum, DepositFix}
use tests/utils/params.{DepositParams, Fixed}
use deposit

test deposit_fix() {
  let asset = helpers.get_asset()
  let consumable_out_ref = helpers.create_out_ref("0101", 0)
  let datum = BankDatum { owner: #"0401" }
  let redeemer = DepositFix

  let depo = DepositParams {
    deposit_type: Fixed,
    beneficiar: #"0402",
    bank_in: 1000,
    staker_in: 200,
    deposit_start: 0,
    deposit_end: 3 * 30 * 24 * 60 * 60 * 1000, // 3 months
    deposit_amount: 100,
  }
  trace "interest:"
  trace cbor.diagnostic(depo |> params.get_interest())
  let (deposit_out, staker_out, bank_out) = depo |> params.get_output_values()

  let script_addr = Address {
    payment_credential: ScriptCredential(#"0201"),
    stake_credential: None
  }

  let staker_addr = Address {
    payment_credential: VerificationKeyCredential(#"0301"),
    stake_credential: None
  }
  
  let tx = Transaction {
    ..transaction.placeholder(),
    inputs: [
      // Staker Input:
      Input {
        output_reference: helpers.create_out_ref("0102", 0),
        output: helpers.make_output(staker_addr, asset, depo.staker_in)
      },
      // Bank Input:
      Input {
        output_reference: consumable_out_ref,
        output: helpers.make_output_datum(script_addr, asset, depo.bank_in, datum)
      }
    ],
    outputs: [
      // Deposit UTxO
      helpers.make_output_datum(script_addr, asset, deposit_out, depo |> params.get_deposit_datum()),
      // Change: Staker UTxO
      helpers.make_output(staker_addr, asset, staker_out),
      // Change: Bank UTxO
      helpers.make_output_datum(script_addr, asset, bank_out, datum),
    ],
  }

  let ctx = ScriptContext {
    purpose: Spend(consumable_out_ref),
    transaction: tx
  }

  deposit.spend(asset, datum, redeemer, ctx)
}
