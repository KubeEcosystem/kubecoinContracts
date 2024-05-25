/// Transaction builders

import {
  Constr,
  Credential,
  Data,
  Lucid,
  OutRef,
  TxComplete,
  UTxO,
} from "lucid";
import { BankDatum, BankDatumT } from "./types.ts";
import { readValidator } from "../utils.ts";

type ScriptRefs = {
  bankTxHash: string;
  depositTxHash: string;
};

export class TxBuilder {
  private bankRefAddrBech32: string = "";
  private bankRefUTxO: UTxO | undefined = undefined;
  private depositRefAddrBech32: string = "";
  private depositRefUTxO: UTxO | undefined = undefined;

  constructor(
    private lucid: Lucid,
    private scriptRefs: ScriptRefs,
    private tokenUnit: string,
  ) {
    console.log(`tokenUnit: ${tokenUnit}`);
  }

  private async fetchScript(txHash: string): Promise<[UTxO, string]> {
    const outRef: OutRef = {
      txHash,
      outputIndex: 0,
    };
    const [utxo] = await this.lucid.utxosByOutRef([outRef]);
    const validator = utxo.scriptRef;
    if (!validator) {
      throw Error("Could not read validator from ref UTxO");
    }

    const validatorAddressBech32 = this.lucid.utils.validatorToAddress(
      validator,
    );
    return [utxo, validatorAddressBech32];
  }

  public async fetchScripts(): Promise<void> {
    [this.depositRefUTxO, this.depositRefAddrBech32] = await this.fetchScript(
      this.scriptRefs.depositTxHash,
    );
    [this.bankRefUTxO, this.bankRefAddrBech32] = await this.fetchScript(
      this.scriptRefs.bankTxHash,
    );
    console.log("TxBuilder. fetchScripts: ", [
      [this.depositRefUTxO, this.depositRefAddrBech32],
      [this.bankRefUTxO, this.bankRefAddrBech32],
    ]);
  }

  public allocate(
    amount: bigint,
    owner: string,
  ): Promise<TxComplete> {
    const bankDatum = Data.to<BankDatumT>(
      {
        owner,
      },
      BankDatum as unknown as BankDatumT,
    );

    return this.lucid
      .newTx()
      .payToContract(
        this.bankRefAddrBech32,
        { inline: bankDatum },
        {
          [this.tokenUnit]: amount,
        },
      )
      .complete();
  }

  public async withdrawByProvider(
    address: string,
    amount: bigint,
  ): Promise<TxComplete> {
    const cred: Credential = this.lucid.utils.paymentCredentialOf(
      this.bankRefAddrBech32,
    );
    const utxos = await this.lucid.utxosAtWithUnit(cred, this.tokenUnit);
    console.log("withdrawByProvider. utxos: ", utxos);
    const utxo = utxos[0];

    // const owner = this.lucid.utils
    //   .getAddressDetails(address)
    //   .paymentCredential!.hash;

    // const bankDatum = Data.to<BankDatumT>(
    //   {
    //     owner,
    //   },
    //   BankDatum as unknown as BankDatumT,
    // );

    const redeemer = Data.to(new Constr(3, []));

    //const validator = readValidator("bank.spend");

    return this.lucid
      .newTx()
      .readFrom([this.bankRefUTxO!])
      .collectFrom([utxo], redeemer)
      .payToContract(
        this.bankRefAddrBech32,
        { inline: utxo.datum! },
        {
          [this.tokenUnit]: utxo.assets[this.tokenUnit] - amount,
        },
      )
      .payToAddress(address, {
        [this.tokenUnit]: amount,
      })
      .addSigner(address)
      //.attachSpendingValidator(validator)
      .complete();
  }
}
