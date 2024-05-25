import { Address, applyParamsToScript, Data, SpendingValidator } from "lucid";
import { getPlutusBlueprint } from "../../utils.ts";
import { ApyParams, ApyParamsT, AssetClass, AssetClassT } from "../../types.ts";

// ============================================================================
// == Type Definitions

const ValidatorParam = Data.Tuple([
  Data.Bytes(),
  ApyParams,
  AssetClass,
]);
type ValidatorParamT = Data.Static<typeof ValidatorParam>;

// ============================================================================
// == Main

const validator = getPlutusBlueprint("bank.spend");

const SCRIPT: SpendingValidator["script"] = validator.compiledCode;

export function buildBankValidator(
  deposit_validator_addr: Address,
  apy_params: ApyParamsT,
  asset: AssetClassT,
): SpendingValidator {
  const appliedValidator = applyParamsToScript<ValidatorParamT>(
    SCRIPT,
    [deposit_validator_addr, apy_params, asset],
    ValidatorParam as unknown as ValidatorParamT,
  );

  return {
    type: "PlutusV2",
    script: appliedValidator,
  };
}
