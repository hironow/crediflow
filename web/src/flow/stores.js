import { writable } from 'svelte/store';

/** @type {import('svelte/store').Writable<any>} */
export const user = writable(null);
/** @type {import('svelte/store').Writable<number>} */
export const transactionStatus = writable(-1);
export const transactionInProgress = writable(false);
/** @type {import('svelte/store').Writable<string | null>} */
export const txId = writable(null);

// crediflow
/** @type {import('svelte/store').Writable<string>} */
export const host = writable('0x497866d0e68bf2cf'); // default host is prepared for testnet
/** @type {import('svelte/store').Writable<any[]>} */
export const contents = writable([]);
/** @type {import('svelte/store').Writable<Record<string, any>>} */
export const creatorNFTHoldersMap = writable({}); // key: contentId
/** @type {import('svelte/store').Writable<Record<string, any>>} */
export const admirerNFTHoldersMap = writable({}); // key: contentId
export const newContent = writable({
	name: '',
	creators: [{ address: '', role: '' }]
});
