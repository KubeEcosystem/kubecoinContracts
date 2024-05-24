use aiken/dict
use aiken/list
use aiken/transaction.{OutputReference, ScriptContext, Transaction} as tx
use aiken/transaction/value

validator(token_name: ByteArray, utxo_ref: OutputReference) {
  fn mint(_redeemer: Data, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    expect tx.Mint(policy_id) = purpose

    let Transaction { inputs, mint, .. } = transaction

    expect [(asset_name, _amount)] =
      mint
        |> value.from_minted_value
        |> value.tokens(policy_id)
        |> dict.to_list()

    let must_spend_utxo_from_script_parameter =
      inputs |> list.any(fn(input) { input.output_reference == utxo_ref })

    and {
      must_spend_utxo_from_script_parameter?,
      (asset_name == token_name)?,
    }
  }
}
