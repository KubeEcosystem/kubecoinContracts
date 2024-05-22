use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Transaction
}
use aiken/transaction/value
use aiken/cbor
use deposit/types.{ AssetClass, Datum, Redeemer, DepositFix, WithdrawFlex, WithdrawFix, ProviderWithdraw, BankDatum, DepositFixDatum }
use deposit/utils
use deposit/apy

validator(asset: AssetClass) {
  pub fn spend(datum: Datum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    let spendable_utxo = utils.get_spendable_utxo(ctx)
    let quantity_of = value.quantity_of(_, asset.policy, asset.name)
    trace @"spendable_utxo.address:"
    trace cbor.diagnostic(spendable_utxo.address)
    when redeemer is {
      DepositFix -> {
        trace @"DepositFix"
        
        // Tx: staker_in + bank_in = deposit_out + staker_out + bank_out
        expect BankDatum(bank_owner) = datum

        expect [bank_input] = ctx.transaction.inputs |> list.filter(fn (i) {
          trace "i.output.address:"
          trace cbor.diagnostic(i.output.address)
          and {
            i.output.address == spendable_utxo.address,
            when i.output.datum is {
              InlineDatum(inline) -> {
                // all inline datums must be of Datum type
                expect datum: Datum = inline
                when datum is {
                  BankDatum(_) -> True
                  _ -> False
                }
              }
              _ -> False
            }
          }
        })

        let script_outputs: List<(Output, Datum)> = 
          ctx.transaction.outputs
          |> list.filter(fn (o: Output) { o.address == spendable_utxo.address })
          |> list.filter_map(fn (o) {
              when o.datum is {
                InlineDatum(inline) -> {
                  // all inline datums must be of Datum type
                  expect datum: Datum = inline
                  Some((o, datum))
                }
                _ -> None
              }
          })

        let script_outputs_count_must_be_1_or_2 = script_outputs |> list.length |> utils.between(1, 2)

        // Should be exactly one DepositFixDatum output
        expect [(deposit_amount, deposit_start, deposit_end)] = 
          script_outputs 
          |> list.filter_map(fn (item) {
            let (o, d) = item
            let amount = o.value |> quantity_of
            when d is {
              DepositFixDatum(
                _, 
                start, 
                end) -> {
                  Some((amount, start, end))
                }
              _ -> None
            }
          })

        let bank_outputs = script_outputs |> list.filter_map(fn (item) {
          let (o, d) = item
          let amount = o.value |> quantity_of
          when d is {
            BankDatum(owner) -> Some((amount, owner))
            _ -> None
          }
        })

        let bank_outputs_count_must_be_0_or_1 = bank_outputs |> list.length |> utils.between(0, 1)
        
        let bank_output = 
          when bank_outputs is {
            [single] -> Some(single)
            _ -> None
          }

        let staker_fraction = {
          let fold = fn (qty, total) { qty + total }
          let staker_in: Int = ctx.transaction.inputs
            |> list.filter(fn (i) { i.output.address != spendable_utxo.address })
            |> list.map(fn (i) { i.output.value |> quantity_of })
            |> list.foldl(0, fold)
          let staker_out: Int = ctx.transaction.outputs
            |> list.filter(fn (o: Output) { o.address != spendable_utxo.address })
            |> list.map(fn (o) { o.value |> quantity_of })
            |> list.foldl(0, fold)
          staker_in - staker_out
        }

        let bank_fraction = {
          let bank_in = bank_input.output.value |> quantity_of
          let bank_out = when bank_output is {
            Some((bank_out, _)) -> bank_out
            None -> 0
          }
          bank_in - bank_out
        }

        let interest = apy.calc_fix_interest(staker_fraction, deposit_start, deposit_end)

        let bank_owner_must_stay_the_same = when bank_output is {
          Some((_, output_owner)) -> bank_owner == output_owner
          None -> True
        }

        and {
          // expect: 
          // - datum is of type BankDatum
          // - one bank input
          // - all inline datums in script outputs must be of Datum type
          // - exactly one DepositFixDatum output
          script_outputs_count_must_be_1_or_2?,
          bank_outputs_count_must_be_0_or_1?,
          bank_owner_must_stay_the_same?,
          
          // Calculation checks:
          (staker_fraction > 0)?,
          (bank_fraction <= interest)?,
          (deposit_amount == staker_fraction + bank_fraction)?,
        }
      }

      WithdrawFlex -> {
        True
      }

      WithdrawFix -> {
        True
      }
      
      ProviderWithdraw -> {
        trace @"ProviderWithdraw"
        expect BankDatum(owner) = datum
        utils.must_be_signed_by(ctx.transaction, owner)
      }
    }
  }
}
