import { writable } from 'svelte/store';

export const user = writable(null);
export const profile = writable(null);
export const transactionStatus = writable(null);
export const transactionInProgress = writable(false);
export const txId = writable(false);

export const input = writable(null);
export const contents = writable(null);
export const content = writable(null);
