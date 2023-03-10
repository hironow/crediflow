import { writable } from 'svelte/store';

export const user = writable(null);
export const transactionStatus = writable(null);
export const transactionInProgress = writable(false);
export const txId = writable(false);

// crediflow
export const host = writable('0x497866d0e68bf2cf'); // default host is prepared for testnet
export const contents = writable([]);
export const creatorNFTHoldersMap = writable({}); // key: contentId
export const admirerNFTHoldersMap = writable({}); // key: contentId
export const newContent = writable({
	name: '',
	creators: [{ address: '', role: '' }]
});
