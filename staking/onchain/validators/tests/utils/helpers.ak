//// Tests Helpers

use common/types.{AssetClass}
use aiken/transaction.{Spend, OutputReference, Transaction, ScriptContext, Output, TransactionId, NoDatum, InlineDatum}
use aiken/transaction/credential.{Address}
use aiken/transaction/value

pub fn get_asset() -> AssetClass {
  // KUBE coin
  AssetClass {
    policy: #"a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be",
    name: #"4b756265436f696e"
  }
}

pub fn get_placeholder_utxo() -> OutputReference {
  OutputReference { transaction_id: TransactionId(""), output_index: 0 }
}

pub fn get_script_context(tx: Transaction) -> ScriptContext {
  ScriptContext { purpose: Spend(get_placeholder_utxo()), transaction: tx }
}

pub fn create_out_ref(tx_id: ByteArray, idx: Int) -> OutputReference {
  OutputReference { transaction_id: TransactionId(tx_id), output_index: idx }
}

pub fn make_output(address: Address, asset: AssetClass, value: Int) -> Output {
  Output {
    address: address,
    value: value.from_asset(asset.policy, asset.name, value),
    datum: NoDatum,
    reference_script: None
  }
}

pub fn make_output_datum(address: Address, asset: AssetClass, value: Int, datum) -> Output {
  Output {
    address: address,
    value: value.from_asset(asset.policy, asset.name, value),
    datum: InlineDatum(datum),
    reference_script: None
  }
}
