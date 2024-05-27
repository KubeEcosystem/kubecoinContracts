import type { Signal } from "@preact/signals";
import { Button } from "../components/Button.tsx";
import { useEffect, useState } from "preact/hooks";
import { Blockfrost, Lucid, TxComplete, fromText } from "lucid/mod.ts";
import { TxBuilder } from "../cardano/tx_builder.ts";

const createLucid = async (blockFrostId: string) => {
  const lucid = await Lucid.new(
    new Blockfrost(
      "https://cardano-preprod.blockfrost.io/api/v0",
      blockFrostId,
    ),
    "Preprod",
  );
  return lucid;
};

let lucid: Lucid;
let txBuilder: TxBuilder;






export default function SPA() {
  const [blockFrostId, setBlockFrostId] = useState<string>("");
  const [owner, setOwner] = useState<string>();

  


  const onConnection = async () => {
    console.log("blockFrostId", blockFrostId);
    lucid = await createLucid(blockFrostId);
    (window as any).lucid = lucid;
    console.log("lucid.network: ", lucid.network);
    
    let wallet;
    if (window.cardano && window.cardano.nami) {
        wallet = await window.cardano.nami.enable();
        console.log("Nami wallet enabled");
    } else if (window.cardano && window.cardano.eternl) {
        wallet = await window.cardano.eternl.enable();
        console.log("Eternl wallet enabled");
    } else {
        console.error("No compatible wallet found");
        return;
    }

    lucid.selectWallet(wallet);

    const publicKeyHash = lucid.utils
      .getAddressDetails(await lucid.wallet.address())
      .paymentCredential
      ?.hash;
    setOwner(publicKeyHash);
    console.log(`publicKeyHash for owner: ${publicKeyHash}`);

    const { paymentCredential } = lucid.utils.getAddressDetails(
      await lucid.wallet.address(),
    );

    console.log(`paymentCredential for owner: ${paymentCredential}`);
  }

  const onCreateLucid = async () => {
    console.log("blockFrostId", blockFrostId);

    lucid = await createLucid(blockFrostId);
    (window as any).lucid = lucid;

    console.log("lucid.network: ", lucid.network);

    let wallet;
    if (window.cardano && window.cardano.nami) {
        wallet = await window.cardano.nami.enable();
        console.log("Nami wallet enabled");
    } else if (window.cardano && window.cardano.eternl) {
        wallet = await window.cardano.eternl.enable();
        console.log("Eternl wallet enabled");
    } else {
        console.error("No compatible wallet found");
        return;
    }

    lucid.selectWallet(wallet);

    const publicKeyHash = lucid.utils
      .getAddressDetails(await lucid.wallet.address())

      .paymentCredential
      ?.hash;
    setOwner(publicKeyHash);
    console.log(`publicKeyHash for owner: ${publicKeyHash}`);

    const utxos = await lucid.wallet.getUtxos();
    console.log(`balance owner: ${utxos}`);

    txBuilder = new TxBuilder(lucid, {
      depositTxHash:
        "dd834ab4bc942d8cfa026b3d909afe3e885eb6785f4807f51f5d221c81391c9d",
      bankTxHash:
        "9954759a56a193e4e079f01f98720c1d3a46e568f89a0ac1cec5ce8c5264feff",
    }, "2293e75c9ece1abae160d2adb52ed234819b449249ed825119316419746573744b756265");

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

  const onMint = async () => {

    console.log("blockFrostId", blockFrostId);
    lucid = await createLucid(blockFrostId);
    (window as any).lucid = lucid;
    console.log("lucid.network: ", lucid.network);
    
    let wallet;
    if (window.cardano && window.cardano.nami) {
        wallet = await window.cardano.nami.enable();
        console.log("Nami wallet enabled");
    } else if (window.cardano && window.cardano.eternl) {
        wallet = await window.cardano.eternl.enable();
        console.log("Eternl wallet enabled");
    } else {
        console.error("No compatible wallet found");
        return;
    }

    lucid.selectWallet(wallet);

    const publicKeyHash = lucid.utils
      .getAddressDetails(await lucid.wallet.address())
      .paymentCredential
      ?.hash;
    setOwner(publicKeyHash);
    console.log(`publicKeyHash for owner: ${publicKeyHash}`);

    const { paymentCredential } = lucid.utils.getAddressDetails(
      await lucid.wallet.address(),
    );

    console.log(`paymentCredential for owner: ${paymentCredential}`);

    const mintingPolicy = lucid.utils.nativeScriptFromJson(
      {
        type: "all",
        scripts: [
          { type: "sig", keyHash: paymentCredential.hash },
          {
            type: "before",
            slot: lucid.utils.unixTimeToSlot(Date.now() + 1000000),
          },
        ],
      },
    );

    const policyId = lucid.utils.mintingPolicyToId(mintingPolicy);

    const unit = policyId + fromText("TestToken");
    console.log("onMint. lucid.network: ", lucid.network);

    const tx = await lucid.newTx()
      .mintAssets({ [unit]: 1000000n })
      .validTo(Date.now() + 200000)
      .attachMintingPolicy(mintingPolicy)
      .complete();

    const signedTx = await tx.sign().complete();
    const txHash = await signedTx.submit();
    console.log(`txHash: ${txHash}`);
    const success = await lucid!.awaitTx(txHash);
    console.log(`success: ${success}`);

    
  }

  const onBurn = async () => {

    console.log("blockFrostId", blockFrostId);
    lucid = await createLucid(blockFrostId);
    (window as any).lucid = lucid;
    console.log("lucid.network: ", lucid.network);
    
    let wallet;
    if (window.cardano && window.cardano.nami) {
        wallet = await window.cardano.nami.enable();
        console.log("Nami wallet enabled");
    } else if (window.cardano && window.cardano.eternl) {
        wallet = await window.cardano.eternl.enable();
        console.log("Eternl wallet enabled");
    } else {
        console.error("No compatible wallet found");
        return;
    }

    lucid.selectWallet(wallet);

    const { paymentCredential } = lucid.utils.getAddressDetails(
      await lucid.wallet.address(),
    );

    console.log(`paymentCredential for owner: ${paymentCredential}`);

    const mintingPolicy = lucid.utils.nativeScriptFromJson(
      {
        type: "all",
        scripts: [
          { type: "sig", keyHash: paymentCredential.hash },
          {
            type: "before",
            slot: lucid.utils.unixTimeToSlot(Date.now() + 1000000),
          },
        ],
      },
    );

    const policyId = "8abacfbaccf44da3a3703eb12b893afc2b84e793d288842214fd8882";

    const unit = policyId + fromText("TestToken");
    console.log("onBurn. lucid.network: ", lucid.network);

    const tx = await lucid.newTx()
      .mintAssets({ [unit]: -500000n })
      .validTo(Date.now() + 200000)
      .attachMintingPolicy(mintingPolicy)
      .complete();

    const signedTx = await tx.sign().complete();
    const txHash = await signedTx.submit();
    console.log(`txHash: ${txHash}`);
    const success = await lucid!.awaitTx(txHash);
    console.log(`success: ${success}`);

    
  }

  const onTransfer = async () => {
    console.log("onTransfer. lucid.network: ", lucid.network);
    const tx = await lucid.newTx()
      .payToAddress("addr_test1qqzlqhp2jx0mllpf9ly2w8jkpqplcg9puyvc0t6zk88dnst5scrjmkppzd3hzdsgfgk927fgsut266qcrnl5f9pcaqdqt50y8s", { lovelace: 5000000n })
      .complete();
    const signedTx = await tx.sign().complete();
    const txHash = await signedTx.submit();
    console.log(`txHash: ${txHash}`);
    const success = await lucid!.awaitTx(txHash);
    console.log(`success: ${success}`);
  }

  const onTransferToken = async () => {
    const policyId = "a26022096c6a8052987dabbfa94849ab7886cf0bb7840044e017d5be";
    const assetName = "KubeCoin";

    console.log("onTransfer. lucid.network: ", lucid.network);
    const tx = await lucid.newTx()
      .payToAddress("addr_test1qqzlqhp2jx0mllpf9ly2w8jkpqplcg9puyvc0t6zk88dnst5scrjmkppzd3hzdsgfgk927fgsut266qcrnl5f9pcaqdqt50y8s", { lovelace: 5000000n })
      .payToAddress("addr_test1qqzlqhp2jx0mllpf9ly2w8jkpqplcg9puyvc0t6zk88dnst5scrjmkppzd3hzdsgfgk927fgsut266qcrnl5f9pcaqdqt50y8s", { [policyId + fromText(assetName)]: 10n })
      .complete();
    const signedTx = await tx.sign().complete();
    const txHash = await signedTx.submit();
    console.log(`txHash: ${txHash}`);
    const success = await lucid!.awaitTx(txHash);
    console.log(`success: ${success}`);
  }

  const onAllocate = async () => {
    console.log("onAllocate. lucid.network: ", lucid.network);
    console.log(`onAllocate. publicKeyHash for owner: ${owner}`);
    const tx = await txBuilder.allocate(110000n, owner!);
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

        <button className="flex flex-col" onClick={onConnection}>Connection</button>
        
        <button className="flex flex-col" onClick={onCreateLucid}>Create Lucid</button>

        <button className="flex flex-col" onClick={onMint}>Mint</button>

        <button className="flex flex-col" onClick={onBurn}>Burn</button>

        <button className="flex flex-col" onClick={onTransfer}>Transfer</button>

        <button className="flex flex-col" onClick={onTransferToken}>Transfer Native</button>
        
        <button className="flex flex-col" onClick={onAllocate}>Allocate</button>
        
        <button className="flex flex-col" onClick={onWithdrawByProvider}>Withdraw by Provider</button>

      </div>
    </div>
  );
}
