// deno-lint-ignore-file
import { Lucid, Blockfrost } from "https://unpkg.com/lucid-cardano@0.10.7/web/mod.js"

const createLucid = async (blockfrostProjectId) => {
  const lucid = await Lucid.new(
    new Blockfrost(
      "https://cardano-preview.blockfrost.io/api/v0",
      blockfrostProjectId,
    ),
    "Preview",
  );
  return lucid;
};

const lucid = await createLucid();

window.lucid = lucid;

const utxos = await lucid.utxosAt(
  "addr_test1qrkcjnexwn4pvkjejrs98kqe94pqkhg8uyjvcu24zt9d08sz7gztaw2kl2pnafw0e32nxwyy8vptxe04yuecax02lj5q6vzv8q",
);

console.log(utxos);
