import { Data } from "lucid/mod.ts";

export const BankDatum = Data.Object({
  owner: Data.Bytes(),
});

export type BankDatumT = Data.Static<typeof BankDatum>;
