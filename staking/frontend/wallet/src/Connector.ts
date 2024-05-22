import {
  Cardano,
  ConnectionStatus,
  Wallet,
  WalletType,
} from "./types";
import { IWalletApi } from "./wallet-api";
import { walletInfo } from "./wallets-list";
import { PubSub } from "./pubsub";

const walletTypes: WalletType[] = walletInfo.map((i) => i.key);

function isWalletType(key: string): key is WalletType {
  return walletTypes.findIndex((j) => key === j) > -1;
}

const getInitialWalletsList = () =>
  walletInfo.map((i) => ({
    ...i,
    api: undefined,
    status: ConnectionStatus.Unavailable,
  }));

const setUnavailable = (w: Wallet) => {
  w.api = undefined;
  w.status = ConnectionStatus.Unavailable;
};

const updateWalletStatus = async (
  wallet: Wallet,
  available: WalletType[],
  cardano: Cardano
) => {
  if (available.includes(wallet.key)) {
    if (await cardano[wallet.key].isEnabled()) {
      if (wallet.api === undefined) {
        wallet.status = ConnectionStatus.Enabled;
      }
    } else {
      wallet.status = ConnectionStatus.Available;
    }
  } else {
    setUnavailable(wallet);
  }
};

type Events = {
  connect: WalletType;
  disconnect: WalletType;
};

export class Connector {
  private pubSub = new PubSub<Events>();

  private get cardano(): Cardano {
    return (window as any).cardano as Cardano;
  }

  private _current: Wallet | undefined;

  private set current(w: Wallet | undefined) {
    this._current = w;
  }

  private disconnectWallet (w: Wallet) {
    w.api = undefined;
    if (w.status > ConnectionStatus.Enabled) {
      w.status = ConnectionStatus.Enabled;
    }
    this.pubSub.publish('disconnect', w.key);
  };

  list: Wallet[] = getInitialWalletsList();

  async updateStatus() {
    if (!this.cardano) {
      this.list.forEach(setUnavailable);
      return;
    }

    const available = Object.keys(this.cardano).filter(isWalletType);
    const promises = this.list.map((w) =>
      updateWalletStatus(w, available, this.cardano)
    );
    await Promise.all(promises);
  }

  get current(): Wallet | undefined {
    return this._current;
  }

  getByKey(key: WalletType) {
    return this.list.find((i) => i.key === key);
  }

  select(wallet?: WalletType) {
    if (!wallet) {
      this.current = undefined;
    } else {
      const w = this.getByKey(wallet);
      if (w && w.status === ConnectionStatus.Connected) {
        this.current = this.getByKey(wallet);
      }
    }
  }

  async connect(
    wallet: WalletType,
    doNotSelect = false
  ): Promise<IWalletApi | undefined> {
    const w = this.getByKey(wallet);
    if (w) {
      w.api = await this.cardano[wallet].enable();
      w.status = ConnectionStatus.Connected;
      if (!doNotSelect) {
        this.select(wallet);
      }
      this.pubSub.publish('connect', wallet);
      return w.api;
    }
    return undefined;
  }

  disconnect(key?: WalletType) {
    if (!key) {
      if (this.current) {
        this.disconnectWallet(this.current);
        this.current = undefined;
      }
    } else {
      const w = this.list.find((i) => i.key === key);
      if (w) {
        this.disconnectWallet(w);
        if (this.current && this.current.key === key) {
          this.current = undefined;
        }
      }
    }
  }

  public subscribe<E extends keyof Events>(
    event: E,
    callback: (message: Events[E]) => void
  ) {
    return this.pubSub.subscribe(event, callback);
  }

  public unsubscribe<E extends keyof Events>(
    event: E,
    callback: (message: Events[E]) => void
  ) {
    return this.pubSub.subscribe(event, callback);
  }
}
