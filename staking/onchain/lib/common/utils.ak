//// Common Utils

use aiken/transaction.{InlineDatum, Spend, Transaction, ScriptContext, Output}
use aiken/transaction/credential.{VerificationKeyCredential, ScriptCredential}
use aiken/list
use aiken/transaction/value
use common/types.{AssetClass, VerificationKeyHash, ScriptAddress}

pub fn must_be_signed_by(transaction: Transaction, vkh: VerificationKeyHash) -> Bool {
  list.has(transaction.extra_signatories, vkh)
}

pub fn between(self, a, b) -> Bool {
  self >= a && self <= b
}

pub fn get_spendable_output(ctx: ScriptContext) -> Option<Output> {
  when ctx.purpose is {
    Spend(spendable_output_ref) -> {
      let inputs = ctx.transaction.inputs |> list.filter(fn(input) {
        input.output_reference == spendable_output_ref 
      })
      when inputs is {
        [spendable_input] -> Some(spendable_input.output)
        _ -> None
      }
    }
    _ -> None
  }
}

pub fn get_own_input_and_outputs(ctx: ScriptContext) -> (Option<Output>, List<Output>) {
  let own_in = get_spendable_output(ctx)
  when own_in is {
    Some(i) -> {
      let outputs = list.filter(
        ctx.transaction.outputs,
        fn(o) { o.address == i.address }
      )
      (own_in, outputs)
    }
    None -> (own_in, [])
  }
}

pub fn get_script_outputs(outputs: List<Output>, script_addr: ScriptAddress) {
  list.filter(outputs, fn(output) {
    when output.address.payment_credential is {
      ScriptCredential(hash) -> hash == script_addr
      VerificationKeyCredential(_) -> False
    }
  })
}

pub fn get_datum(output: Output) -> Option<Data> {
  when output.datum is {
    InlineDatum(inline) -> {
      Some(inline)
    }
    _ -> None
  }
}

pub fn get_asset_balance(ctx: ScriptContext, asset: AssetClass, filter: fn (Output) -> Bool) -> (Int, Int) {
  let quantity_of = value.quantity_of(_, asset.policy, asset.name)
  let fold = fn (qty, total) { qty + total }
  let inputs_total: Int = ctx.transaction.inputs
    |> list.filter(fn (i) { filter(i.output) })
    |> list.map(fn (i) { i.output.value |> quantity_of })
    |> list.foldl(0, fold)
  let outputs_total: Int = ctx.transaction.outputs
    |> list.filter(filter)
    |> list.map(fn (o) { o.value |> quantity_of })
    |> list.foldl(0, fold)
  (inputs_total, outputs_total)
}