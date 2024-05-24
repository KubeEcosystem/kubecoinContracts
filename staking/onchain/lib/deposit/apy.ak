//// Interest calculation formulas

use aiken/time.{PosixTime}
use aiken/cbor
use aiken/math
use aiken/list

pub type ApyTier {
  max_duration_secs: Int,
  /// APY: Percents multiplied by 100
  apy: Int
}

fn calculate(amount: Int, seconds: Int, apy: Int) {
  trace "calculate interest: amount, apy, seconds"
  trace cbor.diagnostic(amount)
  trace cbor.diagnostic(apy)
  trace cbor.diagnostic(seconds)
  amount * apy * seconds / (100 * 100 * 365 * 24 * 60 * 60)
}

fn get_last_tier(params: List<ApyTier>) -> ApyTier {
  let last_tier = params |> list.last
  when last_tier is {
    /// provide arbitrary default params. 
    /// This should never happen, unless admin doesn't provide APY tiers in script params.
    None -> ApyTier(12 * 30 * 24 * 60 * 60, 1350)
    Some(t) -> t
  }
}

pub fn get_deposit_period_in_seconds(params: List<ApyTier>, start: PosixTime, end: PosixTime) -> Int {
  let last_tier = get_last_tier(params)
  let secs = (end - start) / 1000
  if secs < 0 { // sneaky things detected
    0
  } else {
    math.min(last_tier.max_duration_secs, secs)
  }
}

pub fn get_fix_deposit_apy(params: List<ApyTier>, secs: Int) -> Int {
  let tier_maybe = params |> list.find(fn (p) {
    secs <= p.max_duration_secs
  })
  
  let tier = when tier_maybe is {
    Some(t) -> t
    None -> get_last_tier(params)
  }
  
  tier.apy
}

/// It is assumed that params list is ordered by max_duration_secs.
pub fn calc_fix_interest(params: List<ApyTier>, amount: Int, start: PosixTime, end: PosixTime) -> Int {
  let secs = get_deposit_period_in_seconds(params, start, end)
  let apy = get_fix_deposit_apy(params, secs)
  calculate(amount, secs, apy)
}

/// It is assumed that params list is ordered by max_duration_secs.
pub fn calc_flex_interest(apy: Int, amount: Int, start: PosixTime, end: PosixTime) -> Int {
  let seconds = (end - start) / 1000
  let secs = if seconds < 0 { 
    0 
  } else { 
    seconds 
  }
  calculate(amount, secs, apy)
}