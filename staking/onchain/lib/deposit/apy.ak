//// Interest calculation formulas

use aiken/time.{PosixTime}
use aiken/cbor
use aiken/math

/// apy: Percents multiplied by 100
pub fn calc_interest(amount: Int, seconds: Int, apy: Int) {
  trace "calc_interest: amount, apy, seconds"
  trace cbor.diagnostic(amount)
  trace cbor.diagnostic(apy)
  trace cbor.diagnostic(seconds)
  amount * apy * seconds / (100 * 100 * 365 * 24 * 60 * 60)
}

pub fn get_deposit_period_in_seconds(start: PosixTime, end: PosixTime) -> Int {
  let secs = (end - start) / 1000
  if secs < 0 { // sneaky things detected
    0
  } else {
    math.min(12 * 30 * 24 * 60 * 60, secs) // Not more than 12 months is counted
  }
}

/// apy: Percents multiplied by 100
pub fn get_fix_deposit_apy(secs: Int) -> Int {
  if secs <= 6 * 30 * 24 * 60 * 60 {
    1050
  } else {
    1350
  }
}

pub fn calc_fix_interest(amount: Int, start: PosixTime, end: PosixTime) -> Int {
  let secs = get_deposit_period_in_seconds(start, end)
  let apy = get_fix_deposit_apy(secs)
  calc_interest(amount, secs, apy)
}