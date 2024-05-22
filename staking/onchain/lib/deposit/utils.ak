//// Helper Functions

use aiken/transaction.{Spend, Transaction, ScriptContext, Output}
use deposit/types.{VerificationKeyHash}
use aiken/list

pub fn must_be_signed_by(transaction: Transaction, vkh: VerificationKeyHash) -> Bool {
  list.has(transaction.extra_signatories, vkh)
}

pub fn get_spendable_utxo(ctx: ScriptContext) -> Output {
  expect Spend(spendable_output_ref) = ctx.purpose
  expect [spendable_input] =
    ctx.transaction.inputs 
    |> list.filter(fn(input) { input.output_reference == spendable_output_ref })
  spendable_input.output
}

pub fn between(self, a, b) -> Bool {
  self >= a && self <= b
}
