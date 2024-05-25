import { TxHash } from "lucid";
import { buildDepositValidator } from "../build/deposit.ts";
import { makeDeployTx, selectWallet } from "../../utils.ts";
import { AssetClassT } from "../../types.ts";

async function deployDeposit(
  asset: AssetClassT,
): Promise<TxHash> {
  console.log("deployDeposit");
  console.log(arguments);
  const lucid = await selectWallet();
  const validator = buildDepositValidator(asset);
  const tx = await makeDeployTx(lucid, validator);

  const signedTx = await tx.sign().complete();
  const txHash = await signedTx.submit();

  const success = await lucid.awaitTx(txHash);
  console.log(`success? ${success}`);

  return txHash;
}

export { deployDeposit };
