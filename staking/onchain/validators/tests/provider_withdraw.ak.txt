//// ProviderWithdraw Tests

use aiken/transaction.{Spend, ScriptContext, OutputReference, Transaction, TransactionId, Input, Output, NoDatum}
use aiken/transaction/credential.{Address, ScriptCredential}
use aiken/transaction/value
use deposit/types.{Datum, Redeemer, BankDatum, ProviderWithdraw, DepositFlexDatum, DepositFixDatum}
use tests/utils/helpers
use deposit

// ============================================================================
// == Helper functions

fn get_provider_withdraw_data() -> (Datum, Redeemer, ScriptContext) {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let out_ref = OutputReference { transaction_id: TransactionId(""), output_index: 0 }

  let d: Datum = BankDatum { owner }
  let r: Redeemer = ProviderWithdraw

  let tx = Transaction {
    ..transaction.placeholder(),
    inputs: [
      Input {
        output_reference: out_ref,
        output: Output {
          address: Address {
            payment_credential: ScriptCredential(#"01"),
            stake_credential: None,
          },
          value: value.zero(),
          datum: NoDatum,
          reference_script: None,
        }
      }
    ],
    extra_signatories: [owner]
  }

  let c = ScriptContext {
    purpose: Spend(out_ref),
    transaction: tx
  }
  (d, r, c)
}


// ============================================================================
// == Tests

test withdraw_1() {
  let a = helpers.get_asset()
  let (d, r, c) = get_provider_withdraw_data()
  deposit.spend(a, d, r, c)
}

test withdraw_fail_1() fail {
  let a = helpers.get_asset()
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let (_, r, c) = get_provider_withdraw_data()
  let d = DepositFlexDatum { beneficiar: owner, deposit_start: 0 }
  deposit.spend(a, d, r, c)
}

test withdraw_fail_2() fail {
  let a = helpers.get_asset()
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let (_, r, c) = get_provider_withdraw_data()
  let d = DepositFixDatum { beneficiar: owner, deposit_start: 0, deposit_end: 0 }
  deposit.spend(a, d, r, c)
}