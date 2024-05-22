import { IInitialApi, IWalletApi } from "./wallet-api";

export type WalletType = 
    'flint'
  | 'nami'
  | 'eternl'
  | 'gerowallet'
  | 'nufi'
  | 'begin'
  | 'lace'
  | 'yoroi';

export enum NetworkId {
  MAINNET = 1,
  TESTNET = 0,
}


export interface IWalletInfo {
  key: WalletType;
  name: string;
  link: string;
  icon: string;
}

export enum ConnectionStatus {
  Unavailable = 0, // Wallet is not in window.cardano object. That means wallet extension is not installed in users browser.
  Available, // Wallet is in window.cardano object. Extension installed.
  Enabled, // isEnabled() = true. Means user whitelisted URL in wallet extension.
  Connected // Connector received and stored API object
}

export type Wallet = IWalletInfo & {
  api: IWalletApi | undefined;
  status: ConnectionStatus;
}

export type Cardano = { [key in WalletType] : IInitialApi};
