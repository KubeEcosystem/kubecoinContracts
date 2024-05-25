import { DepositParamsName } from "./deposit_params.ts";
import { Network } from "./types.ts";

export type DeploymentParams = {
  depositRef: string;
  bankRef: string;
};

type Deployments = Partial<
  Record<Network, Partial<Record<DepositParamsName, DeploymentParams>>>
>;

export const deployments: Deployments = {
  preview: {
    preview1: {
      depositRef:
        "72805977739c053d885203903db70da3349c8b166ecdf20b7864d6e568e521a6.",
      bankRef:
        "54c8f03da9ec69ffcc12f0a9771cd797f73bc4f1d28bc10f752e7fccad1f958f",
    },
  },
};
