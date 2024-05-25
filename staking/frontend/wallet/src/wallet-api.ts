// A hex-encoded string representing CBOR corresponding to T defined via CDDL either inside of the 
// Shelley Multi-asset binary spec or, if not present there, from the CIP-0008 signing spec. 
// This representation was chosen when possible as it is consistent across the Cardano ecosystem 
// and widely used by other tools, such as cardano-serialization-lib, which has support to encode 
// every type in the binary spec as CBOR bytes.
type CBOR = Uint8Array | string;

// A string representing an address in either bech32 format, or hex-encoded bytes. 
// All return types containing Address must return the hex-encoded bytes format, 
// but must accept either format for inputs.
type Address = string;

// A hex-encoded string of the corresponding bytes. 
type Bytes = string;

type Paginate = {
  page: number,
  limit: number,
};

type DataSignature = {
  signature: CBOR,
  key: CBOR,
};

type Extension = { cip: number };

export interface IWalletApi {
  getNetworkId: () => Promise<number>;
  getUtxos: (amount?: CBOR, paginate?: Paginate) => Promise<string>;
  getCollateral: (params: { amount: CBOR }) => Promise<string>;
  getBalance: () => Promise<string>;
  getUsedAddresses: (paginate?: Paginate) => Promise<string[]>;
  getUnusedAddresses: () => Promise<string>;
  getChangeAddress: () => Promise<string>;
  getRewardAddresses: () => Promise<string>;
  signTx(tx: CBOR, partialSign?: boolean): Promise<string>;
  signData(addr: Address, payload: Bytes): Promise<DataSignature>;
  submitTx(tx: CBOR): Promise<string>;
}

export interface IInitialApi {
  apiVersion: string;
  enable: (extensions?: Extension) => Promise<IWalletApi>;
  icon: string;
  isEnabled: () => Promise<boolean>;
  name: string;
  supportedExtensions: Extension[];
}
