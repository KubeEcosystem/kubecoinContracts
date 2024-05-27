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
        "dd834ab4bc942d8cfa026b3d909afe3e885eb6785f4807f51f5d221c81391c9d",
      bankRef:
        "9954759a56a193e4e079f01f98720c1d3a46e568f89a0ac1cec5ce8c5264feff",
    },
  },
};
