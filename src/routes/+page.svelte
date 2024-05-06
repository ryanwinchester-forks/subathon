<script lang="ts">
	import { onMount } from 'svelte';

	export let data;
	let { session, supabase } = data;
	$: ({ session, user } = data);

	import * as Dialog from '$lib/components/ui/dialog';
	import { Button } from '$lib/components/ui/button/index.js';

	let dialogOpen = false;

	const milliSecondsInADay = 24 * 60 * 60 * 1000;
	const today = new Date();

	const { CheckinsWithProfiles } = data;

	const dateOptions: Intl.DateTimeFormatOptions = {
		weekday: 'long',
		month: 'long',
		day: 'numeric'
	};

	let dates: Date[] =
		CheckinsWithProfiles?.map(
			(checkin: typeof CheckinsWithProfiles) => new Date(checkin.created_at)
		) || [];

	let datesSorted = dates.sort((a: Date, b: Date) => {
		return b.getTime() - a.getTime();
	});

	const datesSortedLocaleString = datesSorted.map((date: Date) =>
		date.toLocaleDateString('en-US', dateOptions)
	);

	const datesSet: string[] = [...new Set(datesSortedLocaleString)];

	interface DatesWithCheckins {
		date: string;
		checkins: string[];
	}

	let datesWithCheckins: Array<DatesWithCheckins> = [];

	if (datesSet) {
		datesWithCheckins = [
			...datesSet.map((date) => ({
				date,
				checkins: []
			}))
		];
	}

	if (CheckinsWithProfiles) {
		for (let i = 0; i < CheckinsWithProfiles.length; i++) {
			const checkin = CheckinsWithProfiles[i];

			const formattedDate = new Date(checkin.created_at).toLocaleDateString('en-US', dateOptions);

			for (let j = 0; j < datesSet.length; j++) {
				const date = datesSortedLocaleString[j];
				if (formattedDate === date) {
					datesWithCheckins[j].checkins.push(checkin.profiles?.pfp_url);
				}
			}
		}
	}

	let twitchReady: boolean = false;

	onMount(() => {
		twitchReady = true;
		console.log('onMount: ', dates);
	});
</script>

<div class="h-3 w-full bg-pink-500"></div>
<div class="h-3 w-full bg-violet-700"></div>
<div class="h-3 w-full bg-blue-900"></div>

<div class="min-w-screen flex min-h-screen flex-col items-center gap-16 bg-neutral-950 p-8">
	{#if twitchReady}
		<iframe
			loading="lazy"
			title="thecoppinger Twitch Stream"
			src="https://player.twitch.tv/?autoplay=true&muted=true&parent=www.thecoppinger.com&channel=thecoppinger"
			height="300px"
			width="400px"
		>
		</iframe>
	{:else}
		<div class="h-[300px] w-full bg-slate-500"></div>
	{/if}

	<!-- <pre>{JSON.stringify(CheckinsWithProfiles, null, 2)}</pre> -->

	{#if datesWithCheckins[0]?.date !== new Date().toLocaleDateString('en-US', dateOptions)}
		<p class="text-xl font-semibold text-slate-400">
			{new Date().toLocaleDateString('en-US', dateOptions)}
		</p>
		{#if session?.user}
			<form action="?/check_in" method="POST">
				<Button type="submit">Check-in</Button>
			</form>
		{:else}
			<Dialog.Root bind:open={dialogOpen}>
				<Dialog.Trigger>
					<Button>Check-in</Button>
				</Dialog.Trigger>
				<Dialog.Content>
					<Dialog.Header>
						<Dialog.Title>Login with Twitch</Dialog.Title>
						<Dialog.Description>
							You'll need to login with your Twitch account to check-in.
						</Dialog.Description>
					</Dialog.Header>
					<Dialog.Footer>
						<Button variant="outline" on:click={() => (dialogOpen = false)}>Cancel</Button>
						<form action="?/login" method="POST">
							<Button type="submit">Login</Button>
						</form>
					</Dialog.Footer>
				</Dialog.Content>
			</Dialog.Root>
		{/if}
	{/if}
	{#each datesWithCheckins as date, i}
		<p class="text-xl font-semibold text-slate-400">
			{date.date}
		</p>
		<div class="flex flex-wrap gap-2">
			{#each date.checkins as checkin}
				<img class="h-16 w-16 rounded-full" src={checkin} alt="" />
			{/each}
		</div>
		{#if new Date().toLocaleDateString('en-US', dateOptions) === date.date}
			{#if session?.user}
				<form action="?/check_in" method="POST">
					<Button type="submit">Check-in</Button>
				</form>
			{:else}
				<Dialog.Root bind:open={dialogOpen}>
					<Dialog.Trigger>
						<Button>Check-in</Button>
					</Dialog.Trigger>
					<Dialog.Content>
						<Dialog.Header>
							<Dialog.Title>Login with Twitch</Dialog.Title>
							<Dialog.Description>
								You'll need to login with your Twitch account to check-in.
							</Dialog.Description>
						</Dialog.Header>
						<Dialog.Footer>
							<Button variant="outline" on:click={() => (dialogOpen = false)}>Cancel</Button>
							<form action="?/login" method="POST">
								<Button type="submit">Login</Button>
							</form>
						</Dialog.Footer>
					</Dialog.Content>
				</Dialog.Root>
			{/if}
		{/if}
	{/each}
	<form action="?/dummydata" method="POST">
		<button>Dummy Data</button>
	</form>
</div>
