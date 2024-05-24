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
        "00af300cf90491f547defba5a53e2062875c98797fd400f5cf5bb5d7e4c11836",
      bankRef:
        "453518be84000297059e80a2172c9a98d86a64b697aa16b9e8c95344d15bdf9a",
    },
  },
};
