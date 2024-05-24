import { bech32 } from 'bech32';
import { Buffer } from 'buffer';
import { NetworkId } from './types';

/**
 * Same as Buffer.from('asd', 'utf-8').toString('hex');
 * @param src 
 * @returns 
 */
export const hexEncode = (src: string): string => {
  let hexMessage = '';
  for (var i = 0, l = src.length; i < l; i++) {
    hexMessage += src.charCodeAt(i).toString(16);
  }
  return hexMessage;
}

export const hexDecode = (hex: string): string => {
  let decodedMessage = '';
  
  for (let i = 0; i < hex.length; i += 2) {
    const byte = parseInt(hex.slice(i, i + 2), 16);
    decodedMessage += String.fromCharCode(byte);
  }
  
  return decodedMessage;
}

export const decodeHexAddress = (hexAddress: string) => {
  const address = hexAddress.toLowerCase();
  const addressType = address.charAt(0);
  const networkId = Number(address.charAt(1)) as NetworkId;
  const addressBytes = Buffer.from(address, 'hex');
  const words = bech32.toWords(addressBytes);
  let prefix;

  if (['e', 'f'].includes(addressType)) {
    if (networkId === NetworkId.MAINNET) {
      prefix = 'stake';
    } else if (networkId === NetworkId.TESTNET) {
      prefix = 'stake_test';
    } else {
      throw new TypeError('Unsupported network type');
    }

    return bech32.encode(prefix, words, 1000);
  } else {
    if (networkId === NetworkId.MAINNET) {
      prefix = 'addr';
    } else if (networkId === NetworkId.TESTNET) {
      prefix = 'addr_test';
    } else {
      throw new TypeError('Unsupported network type');
    }

    return bech32.encode(prefix, words, 1000);
  }
};
