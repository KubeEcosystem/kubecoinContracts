import { Data } from "lucid";

export const AssetClass = Data.Object({
  policy: Data.Bytes({ maxLength: 28 }),
  name: Data.Bytes(),
});
export type AssetClassT = Data.Static<typeof AssetClass>;

const ApyTier = Data.Object({
  max_duration_secs: Data.Integer(),
  apy: Data.Integer(),
});
type ApyTierT = Data.Static<typeof ApyTier>;

export const ApyParams = Data.Object({
  fix_tiers: Data.Array(ApyTier),
  flex_apy: Data.Integer(),
});
export type ApyParamsT = Data.Static<typeof ApyParams>;

export const BankDatum = Data.Object({
  owner: Data.Bytes(),
});

export type BankDatumT = Data.Static<typeof BankDatum>;
