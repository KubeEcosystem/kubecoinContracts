import { depositParams, DepositParamsName } from "./deposit_params.ts";
import { deployBank } from "../scripts/deploy/deploy_bank.ts";
import { deployDeposit } from "../scripts/deploy/deploy_deposit.ts";
import { Network } from "./types.ts";
import { OutRef } from "lucid";

type Contract = "all" | "deposit" | "bank";

type ExecutionParams = {
  network: Network;
  depositParamsName: DepositParamsName;
  contract: Contract;
  depositRefTx?: string;
};

function getExecutionParams(): ExecutionParams {
  const network = Deno.args[0] as Network;
  const depositParamsName = (Deno.args[1] || "preview1") as DepositParamsName;
  const contract = (Deno.args[2] || "all") as Contract;
  const depositRefTx = Deno.args[3];

  if (contract === "bank" && !depositRefTx) {
    throw new Error(
      "In order to deploy Bank contract, you need to specify depositRefTx",
    );
  }

  return {
    network,
    depositParamsName,
    contract,
    depositRefTx,
  };
}

function shouldDeploy(
  question: Exclude<Contract, "all">,
  userRequested: Contract,
): boolean {
  return userRequested === "all" || question === userRequested;
}

async function do_deployDeposit(params: ExecutionParams): Promise<void> {
  const txHash = await deployDeposit(depoParams.asset);
  if (!params.depositRefTx) {
    params.depositRefTx = txHash;
  }
  console.log(`deposit txHash: ${txHash}`);
}

async function do_deployBank(params: ExecutionParams): Promise<void> {
  const depositOutRef: OutRef = {
    txHash: params.depositRefTx!,
    outputIndex: 0,
  };
  const txHash = await deployBank(
    depositOutRef,
    depoParams.apy_params,
    depoParams.asset,
  );
  console.log(`bank txHash: ${txHash}`);
}

// ============================================================================
// == Entry point

const execParams = getExecutionParams();

const depoParams = depositParams[execParams.depositParamsName];

if (shouldDeploy("deposit", execParams.contract)) {
  await do_deployDeposit(execParams);
}

console.log("Starting Bank deployment");

if (shouldDeploy("bank", execParams.contract)) {
  await do_deployBank(execParams);
}
