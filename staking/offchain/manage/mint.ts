import { Data, fromText, OutRef, SpendingValidator, toUnit } from "lucid";
import { buildMintDemoValidator } from "../scripts/build/mint_demo.ts";
import { selectWallet } from "../utils.ts";

type ExecutionParams = {
  tokenName: string;
  outRef: OutRef;
};

function getExecutionParams(): ExecutionParams {
  const [txHash, outputIndexStr] = Deno.args[0].split("#");
  const tokenName = Deno.args[1] || "demo";

  const outRef: OutRef = {
    txHash,
    outputIndex: parseInt(outputIndexStr),
  };

  const result: ExecutionParams = {
    tokenName,
    outRef,
  };
  return result;
}

// ============================================================================
// == Entry point

const execParams = getExecutionParams();

const lucid = await selectWallet();

const validator: SpendingValidator = buildMintDemoValidator(
  execParams.tokenName,
  execParams.outRef,
);

const policyId = lucid.utils.mintingPolicyToId(validator);
const tokenNameHex = fromText(execParams.tokenName);
const unit = toUnit(policyId, tokenNameHex);

const [utxo] = await lucid.utxosByOutRef([execParams.outRef]);

const mint_amount = 1_000_000_000n;

console.log(validator);
console.log(policyId);
console.log(utxo);

const tx = await lucid
  .newTx()
  .collectFrom([utxo])
  .attachMintingPolicy(validator)
  .mintAssets(
    { [unit]: mint_amount },
    Data.void(),
  )
  .payToAddress(await lucid.wallet.address(), {
    [unit]: mint_amount,
  })
  .complete();

const signedTx = await tx.sign().complete();
const txHash = await signedTx.submit();

console.log({ txHash });
