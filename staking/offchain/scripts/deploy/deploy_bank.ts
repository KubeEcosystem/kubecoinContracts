import { OutRef, TxHash } from "lucid";
import { buildBankValidator } from "../build/bank.ts";
import {
  getScriptRefValidadorPaymentCreds,
  makeDeployTx,
  selectWallet,
} from "../../utils.ts";
import { ApyParamsT, AssetClassT } from "../../types.ts";

async function deployBank(
  depositOutRef: OutRef,
  apy_params: ApyParamsT,
  asset: AssetClassT,
): Promise<TxHash> {
  console.log("deployBank");
  console.log(arguments);
  const lucid = await selectWallet();
  const deposit_validator_addr = await getScriptRefValidadorPaymentCreds(
    lucid,
    depositOutRef,
  );
  const validator = buildBankValidator(
    deposit_validator_addr,
    apy_params,
    asset,
  );

  const tx = await makeDeployTx(lucid, validator);

  const signedTx = await tx.sign().complete();
  const txHash = await signedTx.submit();

  const success = await lucid.awaitTx(txHash);
  console.log(`success? ${success}`);

  return txHash;
}

export { deployBank };
