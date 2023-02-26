import { writable } from 'svelte/store';

export const user = writable(null);
export const profile = writable(null);
export const transactionStatus = writable(null);
export const transactionInProgress = writable(false);
export const txId = writable(false);

export const contents = writable([]);
export const creatorNFTHoldersMap = writable({}); // key: contentId
export const admirerNFTHoldersMap = writable({}); // key: contentId

export const input = writable(null);
export const content = writable(null);
