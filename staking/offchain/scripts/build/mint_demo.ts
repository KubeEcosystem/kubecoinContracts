import {
  applyParamsToScript,
  Constr,
  fromText,
  OutRef,
  SpendingValidator,
} from "lucid";
import { getPlutusBlueprint } from "../../utils.ts";

// ============================================================================
// == Main

const validator = getPlutusBlueprint("demo/demo_token.mint");

const SCRIPT: SpendingValidator["script"] = validator.compiledCode;

export function buildMintDemoValidator(
  tokenName: string,
  outputReference: OutRef,
): SpendingValidator {
  const outRef = new Constr(0, [
    new Constr(0, [outputReference.txHash]),
    BigInt(outputReference.outputIndex),
  ]);

  const appliedValidator = applyParamsToScript(
    SCRIPT,
    [fromText(tokenName), outRef],
  );

  return {
    type: "PlutusV2",
    script: appliedValidator,
  };
}
