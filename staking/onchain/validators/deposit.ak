use aiken/dict
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/time.{PosixTime}
use aiken/transaction.{
  InlineDatum, OutputReference, ScriptContext, Spend, Transaction, TransactionId,
}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value

// ============================================================================
// == Types

pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type Datum {
  BankDatum { owner: VerificationKeyHash }
  DepositFlexDatum { beneficiar: VerificationKeyHash, depositStart: PosixTime }
  DepositFixDatum {
    beneficiar: VerificationKeyHash,
    depositStart: PosixTime,
    depositEnd: PosixTime,
  }
}

pub type Redeemer {
  // Spend Bank UTxO
  DepositFix
  StakerWithdraw
  ProviderWithdraw
}

// ============================================================================
// == Helper Functions

fn must_be_signed_by(transaction: Transaction, vkh: VerificationKeyHash) {
  list.has(transaction.extra_signatories, vkh)
}

// ============================================================================
// == Validators

validator {
  fn spend(datum: Datum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    let kube_policy_id =
      #"a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be"
    when redeemer is {
      DepositFix -> {
        let outputs =
          list.filter_map(
            ctx.transaction.outputs,
            fn(o) {
              when o.datum is {
                InlineDatum(data) -> {
                  expect datum_data: Datum = data
                  expect DepositFixDatum(_, start, end) = datum_data
                  // ToDo: ensure aiken behaviour
                  Some((o, start, end))
                }
                _ -> None
              }
            },
          )
        expect 1 = list.length(outputs)
        expect Some((output, start, end)) = list.head(outputs)

        expect [(_, amount)] =
          output.value
            |> value.tokens(kube_policy_id)
            |> dict.to_list()

        True
      }

      // single Deposit tx with datum
      // amount check
      //datum
      StakerWithdraw -> False
      ProviderWithdraw -> {
        expect BankDatum(owner) = datum
        must_be_signed_by(ctx.transaction, owner)
      }
    }
  }
}

// ============================================================================
// == Tests: Helpers

fn get_placeholder_utxo() -> OutputReference {
  OutputReference { transaction_id: TransactionId(""), output_index: 0 }
}

fn get_script_context(tx: Transaction) -> ScriptContext {
  ScriptContext { purpose: Spend(get_placeholder_utxo()), transaction: tx }
}

fn get_provider_withdraw_data() -> (Datum, Redeemer, ScriptContext) {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let d = BankDatum { owner }
  let r = ProviderWithdraw
  let c =
    get_script_context(
      Transaction { ..transaction.placeholder(), extra_signatories: [owner] },
    )
  (d, r, c)
}

// ============================================================================
// == Tests

test provider_withdraw() {
  let (d, r, c) = get_provider_withdraw_data()
  spend(d, r, c)
}

test provider_withdraw_fail_1() fail {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let (_, r, c) = get_provider_withdraw_data()
  let d = DepositFlexDatum { beneficiar: owner, depositStart: 0 }
  spend(d, r, c)
}

test provider_withdraw_fail_2() fail {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let (_, r, c) = get_provider_withdraw_data()
  let d = DepositFixDatum { beneficiar: owner, depositStart: 0, depositEnd: 0 }
  spend(d, r, c)
}

test deposit_fix() {
  let owner = #"00000000000000000000000000000000000000000000000000000000"
  let d = BankDatum { owner }
  let r = ProviderWithdraw
  let c =
    ScriptContext {
      purpose: Spend(get_placeholder_utxo()),
      transaction: transaction.placeholder()
        |> fn(tx) { Transaction { ..tx, extra_signatories: [owner] } },
    }
  spend(d, r, c)
}
