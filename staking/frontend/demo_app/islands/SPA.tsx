import type { Signal } from "@preact/signals";
import { Button } from "../components/Button.tsx";
import { useEffect, useState } from "preact/hooks";
import { Blockfrost, Lucid, TxComplete } from "lucid/mod.ts";
import { TxBuilder } from "../cardano/tx_builder.ts";

const createLucid = async (blockFrostId: string) => {
  const lucid = await Lucid.new(
    new Blockfrost(
      "https://cardano-preview.blockfrost.io/api/v0",
      blockFrostId,
    ),
    "Preview",
  );
  return lucid;
};

let lucid: Lucid;
let txBuilder: TxBuilder;

export default function SPA() {
  const [blockFrostId, setBlockFrostId] = useState<string>("");
  const [owner, setOwner] = useState<string>();

  const onCreateLucid = async () => {
    console.log("blockFrostId", blockFrostId);

    lucid = await createLucid(blockFrostId);
    (window as any).lucid = lucid;

    console.log("lucid.network: ", lucid.network);

    const wallet = await window.cardano
      .eternl
      .enable();

    lucid.selectWallet(wallet);

    const publicKeyHash = lucid.utils
      .getAddressDetails(await lucid.wallet.address())
      .paymentCredential
      ?.hash;
    setOwner(publicKeyHash);
    console.log(`publicKeyHash for owner: ${publicKeyHash}`);

    txBuilder = new TxBuilder(lucid, {
      depositTxHash:
        "72805977739c053d885203903db70da3349c8b166ecdf20b7864d6e568e521a6",
      bankTxHash:
        "54c8f03da9ec69ffcc12f0a9771cd797f73bc4f1d28bc10f752e7fccad1f958f",
    }, "1afba0694f95a270767427a4ca1a8d1fe324853796ef96c07e87424f64656d6f31");

    await txBuilder.fetchScripts();

    // const utxos = await lucid.utxosAt(
    //   "addr_test1qrkcjnexwn4pvkjejrs98kqe94pqkhg8uyjvcu24zt9d08sz7gztaw2kl2pnafw0e32nxwyy8vptxe04yuecax02lj5q6vzv8q",
    // );
    // console.log(utxos);
  };

  const signAndComplete = async (tx: TxComplete) => {
    console.log("signAndComplete");
    const txSigned = await tx.sign().complete();
    console.log("signed");
    const txHash = await txSigned.submit();
    console.log(`txHash: ${txHash}`);
    const success = await lucid!.awaitTx(txHash);
    console.log(`success: ${success}`);
  };

  const onAllocate = async () => {
    console.log("onAllocate. lucid.network: ", lucid.network);
    console.log(`onAllocate. publicKeyHash for owner: ${owner}`);
    const tx = await txBuilder.allocate(1100n, owner!);
    await signAndComplete(tx);
  };

  const onWithdrawByProvider = async () => {
    const tx = await txBuilder.withdrawByProvider(
      await lucid.wallet.address(),
      50n,
    );
    await signAndComplete(tx);
  };

  return (
    <div>
      blockFrostId:
      <label for="blockFrostId"></label>
      <input
        id="blockFrostId"
        type="text"
        value={blockFrostId}
        onInput={(e) => setBlockFrostId(e.currentTarget.value)}
      />
      <div>
        <button className="flex flex-col" onClick={onCreateLucid}>
          Create Lucid
        </button>
        <button className="flex flex-col" onClick={onAllocate}>Allocate</button>
        <button className="flex flex-col" onClick={onWithdrawByProvider}>
          Withdraw by Provider
        </button>
      </div>
    </div>
  );
}
