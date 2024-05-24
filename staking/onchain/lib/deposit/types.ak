//// Deposit Contracs Types

use aiken/time.{PosixTime}
use common/types.{ScriptAddress, VerificationKeyHash}
use deposit/apy.{ApyTier}

pub type ApyParams {
  fix_tiers: List<ApyTier>,
  /// APY: Percents multiplied by 100
  flex_apy: Int,
}

pub type BankDatum {
  owner: VerificationKeyHash,
}

pub type DepositFixDatum {
  deposit_bank_addr: ScriptAddress,
  deposit_bank_owner: VerificationKeyHash,
  deposit_end: PosixTime,
  deposit_bank_fraction: Int,
}

pub type DepositDatum {
  beneficiar: VerificationKeyHash,
  deposit_start: PosixTime,
  /// Required for Fixed deposits, for Flexible should be None
  fixed: Option<DepositFixDatum>,
}

pub type BankRedeemer {
  DepositFlex
  DepositFix
  WithdrawFlex
  WithdrawByProvider
}
