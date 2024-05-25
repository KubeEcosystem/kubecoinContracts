import { Data } from "lucid";

export type Network = "mainnet" | "preprod" | "preview";

export const BankDatum = Data.Object({
  owner: Data.Bytes(),
});

export type BankDatumT = Data.Static<typeof BankDatum>;
