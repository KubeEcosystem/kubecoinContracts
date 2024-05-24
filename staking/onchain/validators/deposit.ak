use aiken/transaction.{
  Output, ScriptContext, Transaction
}
use aiken/transaction/value
// use aiken/cbor
use aiken/interval.{IntervalBound, Finite}
use deposit/types.{ DepositDatum, DepositFixDatum, BankDatum } as deposit_types
use common/types.{ ScriptAddress, AssetClass } as common_types
use common/utils
use deposit/bl

validator(
  bank_validator_addr: ScriptAddress,
  asset: AssetClass,
) {
  pub fn spend(datum: DepositDatum, _redeemer: Data, ctx: ScriptContext) -> Bool {
    let quantity_of = value.quantity_of(_, asset.policy, asset.name)
    
    let is_flexible_deposit = datum.fixed == None
    let must_be_signed_by_beneficiar = utils.must_be_signed_by(ctx.transaction, datum.beneficiar)

    and {
      must_be_signed_by_beneficiar?,
      or {
        is_flexible_deposit,
        {
          // Fixed deposit validation
          expect IntervalBound(Finite(tx_time), _) = ctx.transaction.validity_range.lower_bound

          expect Some(DepositFixDatum (
            deposit_bank_owner,
            deposit_end,
            deposit_bank_fraction
          )) = datum.fixed

          or {
            (tx_time >= deposit_end)?, // No penalties
            {
              // With Penalties
              expect [(bank_out, BankDatum(bank_owner))] = ctx.transaction.outputs 
                |> utils.get_script_outputs(bank_validator_addr)
                |> bl.get_bank_outputs

              let bank_to = bank_out.value |> quantity_of

              and {
                (bank_to == deposit_bank_fraction)?,
                (bank_owner == deposit_bank_owner),
              }
            }
          }
        }
      }
    }
  }
}
