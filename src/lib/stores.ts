import { writable } from 'svelte/store';

export const endDate = writable<Date | null>(null);
export const elapsedTime = writable<number>(0);
export const localTime = writable<string>('');
