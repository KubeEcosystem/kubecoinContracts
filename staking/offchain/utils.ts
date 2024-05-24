import {
  Blockfrost,
  Data,
  fromHex,
  getAddressDetails,
  Lucid,
  OutRef,
  Script,
  SpendingValidator,
  toHex,
  TxComplete,
} from "lucid";
import plutusBlueprint from "../onchain/plutus.json" with {
  type: "json",
};
import * as cbor from "cbor";

export const createLucid = async () => {
  const lucid = await Lucid.new(
    new Blockfrost(
      "https://cardano-preview.blockfrost.io/api/v0",
      Deno.env.get("BLOCKFROST_PROJECT_ID"),
    ),
    "Preview",
  );
  return lucid;
};

export async function selectWallet(): Promise<Lucid> {
  const lucid = await createLucid();
  const seed = Deno.env.get("WALLET_SEED");
  if (!seed) {
    throw Error("Unable to read wallet's seed from env");
  }
  lucid.selectWalletFromSeed(seed);
  return lucid;
}

export function getPlutusBlueprint(title: string) {
  const validator = plutusBlueprint.validators.find((v) => v.title === title);
  if (!validator) {
    throw new Error(`Validator ${title} not present in plutus.json`);
  }
  return validator;
}

export function readValidator(title: string): SpendingValidator {
  const validator = getPlutusBlueprint(title);
  return {
    type: "PlutusV2",
    script: toHex(cbor.encode(fromHex(validator.compiledCode))),
  };
}

export function writeJson(path: string, data: object): string {
  try {
    Deno.writeTextFileSync(path, JSON.stringify(data));
    return "Written to " + path;
  } catch (e) {
    return e.message;
  }
}

export function getAlwaysFailAddrBech32(lucid: Lucid) {
  const alwaysFailValidator = readValidator("always_fail.always_fail");
  return lucid.utils.validatorToAddress(
    alwaysFailValidator,
  );
}

export function makeDeployTx(
  lucid: Lucid,
  validator: Script,
): Promise<TxComplete> {
  const alwaysFailAddressBech32 = getAlwaysFailAddrBech32(lucid);
  return lucid
    .newTx()
    .payToContract(
      alwaysFailAddressBech32,
      { inline: Data.void(), scriptRef: validator },
      { lovelace: 2_000_000n },
    )
    .complete();
}

/// Returns payment credential of validator, sitting at OTxO, specified by OutRef
export async function getScriptRefValidadorPaymentCreds(
  lucid: Lucid,
  outRef: OutRef,
): Promise<string> {
  const [utxo] = await lucid.utxosByOutRef([outRef]);

  const validator = utxo.scriptRef;
  if (!validator) {
    throw Error("Could not read validator from ref UTxO");
  }

  const validatorAddressBech32 = lucid.utils.validatorToAddress(validator);
  const scriptAddress =
    lucid.utils.paymentCredentialOf(validatorAddressBech32).hash;
  return scriptAddress;
}
