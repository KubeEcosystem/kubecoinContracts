# Connect to wallet using CIP30

CIPs:
- https://www.cardano-caniuse.io/
- https://cips.cardano.org/cips/cip30/ 

## Usage

Create connector:

```ts
import { Connector } from 'wallet';
import { ConnectionStatus, WalletType } from "wallet/src/types";
export const walletConnector = new Connector();
```

Connect:

```ts
api = await walletConnector.connect(key);
```

Disconnect:

```ts
walletConnector.disconnect();
```

Tracking events (use in your state manager):

```ts
walletConnector.subscribe('connect', onWalletConnect);
walletConnector.subscribe('disconnect', onWalletDisconnect);
```

Using `walletConnector.current` example:

```ts
const getAddress = async () => {
  const wallet = walletConnector.current;
  if (wallet && wallet.status === ConnectionStatus.Connected && wallet.api) {
    return walletUtils.decodeHexAddress(await wallet.api.getChangeAddress());
  }
}
```

Connect Wallet Dialog: listing all available wallets with status.

```tsx
<For each={walletConnector.list}>
  {(walletInfo: Wallet) => 
    <PanelItem wallet={walletInfo} onClick={() => onConnect(walletInfo.key)} />
  }
</For>
```

## Some related information

The information below is not directly related to this library. It's just food for thought.

- https://developers.cardano.org/docs/integrate-cardano/user-wallet-authentication/ and https://github.com/inimrod/cardano-message-signing-demo
- [Eternl Light Wallet | DApp Connector](https://www.youtube.com/watch?v=7Zbn9fzmhMo) 3 mins video.
- https://github.com/cardano-foundation/cardano-connect-with-wallet

minswap uses walletconnect.com and libs: 

- https://github.com/minswap/wallet-connect/tree/main/packages/wc-dapp This library is a wrapper around Universal Provider for easy integration of Wallet Connect in Cardano dApps. Note, it is only designed to work for Cardano.
- https://github.com/minswap/wallet-connect/tree/main/packages/wc-wallet This library provides a wrapper around @wallet-connect/web3wallet and @wallet-connect/core. It is just a POC to demonstrate working of @minswap/wc-dapp.

walletconnect:

- https://github.com/walletconnect/walletconnect-monorepo
