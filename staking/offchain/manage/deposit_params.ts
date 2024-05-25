import { fromText } from "lucid";
import { ApyParamsT, AssetClassT } from "../types.ts";

export type DepositParams = {
  apy_params: ApyParamsT;
  asset: AssetClassT;
};

const secs = [60, 60, 24, 30].reduce((acc: number[], n) => {
  const last = acc.length === 0 ? 1 : acc[acc.length - 1];
  acc.push(last * n);
  return acc;
}, []);

const secsIn = {
  min: secs[0],
  hour: secs[1],
  day: secs[2],
  month: secs[3],
};

export const depositParams = {
  main: {
    apy_params: {
      fix_tiers: [
        {
          max_duration_secs: BigInt(6 * secsIn.month),
          apy: 1050n,
        },
        {
          max_duration_secs: BigInt(12 * secsIn.month),
          apy: 1350n,
        },
      ],
      flex_apy: 777n,
    },
    asset: {
      policy: "a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be",
      name: fromText("KubeCoin"),
    },
  },
  preview1: {
    apy_params: {
      fix_tiers: [
        {
          max_duration_secs: BigInt(5),
          apy: 10n,
        },
        {
          max_duration_secs: BigInt(10),
          apy: 20n,
        },
        {
          max_duration_secs: BigInt(15),
          apy: 30n,
        },
      ],
      flex_apy: 1000n,
    },
    asset: {
      policy: "1afba0694f95a270767427a4ca1a8d1fe324853796ef96c07e87424f",
      name: fromText("demo1"),
    },
  },
} as const satisfies Record<
  string,
  DepositParams
>;

export type DepositParamsName = keyof typeof depositParams;
