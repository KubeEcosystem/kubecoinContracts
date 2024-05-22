use aiken/hash.{Blake2b_224, Hash}
use aiken/time.{PosixTime}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{AssetName, PolicyId}

// ============================================================================
// == Common Types

pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type AssetClass {
  policy: PolicyId,
  name: AssetName,
}

// ============================================================================
// == Deposit Types

pub type Datum {
  BankDatum { owner: VerificationKeyHash }
  DepositFlexDatum { beneficiar: VerificationKeyHash, deposit_start: PosixTime }
  DepositFixDatum {
    beneficiar: VerificationKeyHash,
    deposit_start: PosixTime,
    deposit_end: PosixTime,
  }
}

pub type Redeemer {
  DepositFix
  WithdrawFlex
  WithdrawFix
  ProviderWithdraw
}
