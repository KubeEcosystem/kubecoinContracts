use aiken/transaction.{ScriptContext}

validator {
  fn always_fail(_redeemer: Data, _ctx: ScriptContext) {
    False
  }
}
