use aiken/list
use aiken/transaction.{
  Input, Output, ScriptContext, Transaction
}
use aiken/transaction/credential.{Address}
use aiken/transaction/value
// use aiken/cbor
use aiken/interval.{IntervalBound, Finite}
use deposit/types.{ DepositDatum, DepositFixDatum, BankDatum, BankRedeemer, DepositFlex, DepositFix, WithdrawFlex, WithdrawByProvider } as deposit_types
use common/types.{ ScriptAddress, AssetClass } as common_types
use common/utils
use deposit/apy
use deposit/bl

validator(
  deposit_validator_addr: ScriptAddress,
  asset: AssetClass,
) {
  pub fn spend(datum: BankDatum, redeemer: BankRedeemer, ctx: ScriptContext) -> Bool {
    let quantity_of = value.quantity_of(_, asset.policy, asset.name)

    when redeemer is {
      DepositFlex -> {
        
        expect (Some(bank_in), [bank_out]) = utils.get_own_input_and_outputs(ctx)

        let bank_out_datum = {
          expect Some(d) = utils.get_datum(bank_out)
          expect bank: BankDatum = d
          bank
        }
        
        expect [(_deposit_out, DepositDatum (_, deposit_start, None))] = ctx.transaction.outputs
          |> utils.get_script_outputs(deposit_validator_addr)
          |> bl.get_deposit_outputs

        let valid_deposit_start = interval.is_entirely_after(ctx.transaction.validity_range, deposit_start)
        let bank_from = bank_in.value |> quantity_of
        let bank_to = bank_out.value |> quantity_of
        let bank_must_keep_same_owner = bank_out_datum.owner == datum.owner

        and {
          bank_must_keep_same_owner?,
          valid_deposit_start?,
          (bank_from == bank_to)?,
        }
      }

      DepositFix -> {
        
        expect (Some(bank_in), [bank_out]) = utils.get_own_input_and_outputs(ctx)
        
        let bank_out_datum = {
          expect Some(d) = utils.get_datum(bank_out)
          expect bank: BankDatum = d
          bank
        }

        expect [(
          deposit_out,
          DepositDatum (
            _,
            deposit_start,
            Some(DepositFixDatum (
              deposit_bank_owner,
              deposit_end,
              deposit_bank_fraction
            ))
          )
        )] = ctx.transaction.outputs
          |> utils.get_script_outputs(deposit_validator_addr)
          |> bl.get_deposit_outputs

        let script_addresses: List<Address> = [
          bank_in,
          deposit_out
        ] |> list.map(fn (i) { i.address })

        let staker_fraction = {
          let (staker_in, staker_out) = utils.get_asset_balance(
            ctx, 
            asset, 
            fn (o) { !list.has(script_addresses, o.address) }
          )
          staker_in - staker_out
        }

        let bank_fraction = {
          let bank_from = bank_in.value |> quantity_of
          let bank_to = bank_out.value |> quantity_of
          bank_from - bank_to
        }
        let interest = apy.calc_fix_interest(staker_fraction, deposit_start, deposit_end)
        
        let deposit_amount = deposit_out.value |> quantity_of
        
        let bank_must_keep_same_owner = bank_out_datum.owner == datum.owner
        let valid_deposit_start = interval.is_entirely_after(ctx.transaction.validity_range, deposit_start)

        and {
          bank_must_keep_same_owner?,
          (deposit_bank_owner == datum.owner)?,
          valid_deposit_start?,
          (deposit_end > deposit_start)?,
          (staker_fraction > 0)?,
          (bank_fraction <= interest)?,
          (deposit_bank_fraction == bank_fraction)?,
          (deposit_amount == staker_fraction + bank_fraction)?,
        }
      }

      WithdrawFlex -> {

        expect (Some(bank_in), bank_outs) = utils.get_own_input_and_outputs(ctx)

        let bank_fraction = {
          let bank_from = bank_in.value |> quantity_of
          let bank_to = when bank_outs is {
            [] -> 0
            outs -> {
              expect [one_bank_output] = outs
              one_bank_output.value |> quantity_of
            }
          }
          bank_from - bank_to
        }

        expect [(deposit_in, DepositDatum (_, deposit_start, None))] = ctx.transaction.inputs
          |> list.map(fn (i) { i.output })
          |> utils.get_script_outputs(deposit_validator_addr)
          |> bl.get_deposit_outputs

        let deposit_amount = deposit_in.value |> quantity_of

        expect IntervalBound(Finite(tx_time), _) = ctx.transaction.validity_range.lower_bound

        let interest = apy.calc_fix_interest(deposit_amount, deposit_start, tx_time)

        let bank_must_keep_same_owner = {
          when bank_outs is {
            [] -> True
            [bank_out] -> {
              expect Some(d) = utils.get_datum(bank_out)
              expect bank_out_datum: BankDatum = d
              bank_out_datum.owner == datum.owner
            }
            _ -> False // Unexpected branch (see above `expect [one_bank_output] = outs`)
          }
        }

        and {
          bank_must_keep_same_owner?,
          (deposit_amount > 0)?,
          (bank_fraction <= interest)?,
        }
      }
      
      WithdrawByProvider -> {
        trace @"WithdrawByProvider"
        let BankDatum(owner) = datum
        utils.must_be_signed_by(ctx.transaction, owner)
      }
    }
  }
}