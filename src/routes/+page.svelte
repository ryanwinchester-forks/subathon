<script lang="ts">
	import { onMount } from 'svelte';

	export let data;
	let { session, supabase } = data;
	$: ({ session, user } = data);

	const { CheckinsWithProfiles } = data;

	const dateOptions: Intl.DateTimeFormatOptions = {
		weekday: 'long',
		month: 'long',
		day: 'numeric'
	};

	let dates: string = CheckinsWithProfiles?.map(
		(checkin: typeof CheckinsWithProfiles) => new Date(checkin.created_at)
	);

	const datesSet: Array<string> = [...new Set(dates)].sort((a, b) => {
		return Date.parse(b) - Date.parse(a);
	});

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
				const date = new Date(datesSet[j]).toLocaleDateString('en-US', dateOptions);
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

	{#each datesWithCheckins as date, i}
		<p class="text-xl font-semibold text-slate-400">
			{new Date(date.date).toLocaleDateString('en-US', dateOptions)}
		</p>
		{#each date.checkins as checkin}
			<img class="h-16 w-16 rounded-full" src={checkin} alt="" />
		{/each}
	{/each}

	<form action="?/dummydata" method="POST">
		<button>Dummy Data</button>
	</form>
</div>
