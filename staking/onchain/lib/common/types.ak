//// Common Types

use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{VerificationKey, Script}
use aiken/transaction/value.{AssetName, PolicyId}

pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type ScriptAddress = Hash<Blake2b_224, Script>

pub type AssetClass {
  policy: PolicyId,
  name: AssetName,
}
