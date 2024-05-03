<script lang="ts">
	import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';

	export let data;
	$: ({ session, user } = data);
	let devMode: boolean = false;

	import { createClient } from '@supabase/supabase-js';

	const client = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);

	const { end_time } = data;

	import { onMount, onDestroy } from 'svelte';

	let endDate: Date = new Date(end_time.end_time); // Replace with your desired end date
	let remainingTime = '';

	const changes = client
		.channel('end-time')
		.on(
			'postgres_changes',
			{
				event: 'UPDATE', // Listen only to UPDATEs
				schema: 'public'
			},
			(payload) => (endDate = new Date(payload.new.end_time))
		)
		.subscribe();

	let intervalId: NodeJS.Timeout;

	function updateRemainingTime() {
		const now: Date = new Date();
		const difference = endDate.getTime() - now.getTime();

		if (difference <= 0) {
			remainingTime = 'Countdown ended';
			clearInterval(intervalId);
			return;
		}

		const days = Math.floor(difference / (1000 * 60 * 60 * 24));
		const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
		const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
		const seconds = Math.floor((difference % (1000 * 60)) / 1000);

		remainingTime = `${days > 0 ? `${days} d` : ''} ${hours} hr ${minutes} m ${seconds} s`;
	}

	// Stopwatch
	let startDate = new Date('2024-05-02T00:01:55+00:00'); // Replace with your desired start date
	let elapsedTime = 0;
	let formattedTime = '0 seconds';

	let stopwatchIntervalId: NodeJS.Timeout;

	function updateElapsedTime() {
		const currentDate = new Date();
		elapsedTime = currentDate.getTime() - startDate.getTime();
		updateFormattedTime();
	}

	function updateFormattedTime() {
		const seconds = Math.floor(elapsedTime / 1000);
		const minutes = Math.floor(seconds / 60);
		const hours = Math.floor(minutes / 60);
		const days = Math.floor(hours / 24);

		const formattedDays = days > 0 ? `${days} d ` : '';
		const formattedHours = hours % 24 > 0 ? `${hours % 24} hr ` : '';
		const formattedMinutes = minutes % 60 > 0 ? `${minutes % 60} m ` : '';
		const formattedSeconds = `${seconds % 60} s`;

		formattedTime =
			`${formattedDays}${formattedHours}${formattedMinutes}${formattedSeconds}`.trim();
	}

	onMount(() => {
		intervalId = setInterval(updateRemainingTime, 1000);

		updateElapsedTime();
		stopwatchIntervalId = setInterval(updateElapsedTime, 1000);
	});

	onDestroy(() => {
		clearInterval(intervalId);
		clearInterval(stopwatchIntervalId);
	});

	updateRemainingTime();

	// Create a variable called `localTime` and set it to the current time in the local timezone.
	let localTime = new Date().toLocaleTimeString();
	// Update the `localTime` variable every second.
	setInterval(() => {
		localTime = new Date().toLocaleTimeString();
	}, 1000);
</script>

<div
	class="min-w-screen iems-end flex min-h-screen flex-col gap-4 p-4 text-neutral-50 opacity-90"
	style={devMode ? 'background-color: black' : 'background-color: #00ff00'}
>
	<button
		class="flex items-center justify-between rounded-2xl bg-neutral-950 p-8 text-3xl tabular-nums"
		on:click={() => (devMode = !devMode)}
	>
		<p class="font-bold">Elapsed: {formattedTime}</p>
		<p class="font-bold">Remaining: {remainingTime}</p>
		<p class="font-bold">Local time: {localTime}</p>
	</button>
</div>
