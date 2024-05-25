import { applyParamsToScript, Data, SpendingValidator } from "lucid";
import { getPlutusBlueprint } from "../../utils.ts";
import { AssetClass, AssetClassT } from "../../types.ts";

// ============================================================================
// == Type Definitions

const ValidatorParam = Data.Tuple([
  AssetClass,
]);
type ValidatorParamT = Data.Static<typeof ValidatorParam>;

// ============================================================================
// == Main

const validator = getPlutusBlueprint("deposit.spend");

const SCRIPT: SpendingValidator["script"] = validator.compiledCode;

export function buildDepositValidator(
  asset: AssetClassT,
): SpendingValidator {
  const appliedValidator = applyParamsToScript<ValidatorParamT>(
    SCRIPT,
    [asset],
    ValidatorParam as unknown as ValidatorParamT,
  );

  return {
    type: "PlutusV2",
    script: appliedValidator,
  };
}
