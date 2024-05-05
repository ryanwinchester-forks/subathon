<script lang="ts">
	import { onMount } from 'svelte';

	import type { Database, Tables, Enums } from '$lib/types/DatabaseDefinitions';

	export let data;
	let { session, supabase } = data;
	$: ({ session, user } = data);

	const { CheckinsWithProfiles } = data;

	let twitchReady: boolean = false;

	onMount(() => {
		twitchReady = true;
	});
</script>

<div class="h-3 w-full bg-pink-500"></div>
<div class="h-3 w-full bg-violet-700"></div>
<div class="h-3 w-full bg-blue-900"></div>

<div class="min-w-screen flex min-h-screen flex-col items-center bg-neutral-950 p-8">
	{#if session?.user}
		<p class=" text-white">Logged in as {session.user.user_metadata.name}</p>
	{:else}
		<p>Not logged in</p>
	{/if}
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

	{#each CheckinsWithProfiles as checkin}
		<img class="h-16 w-16 rounded-full" src={checkin.profiles.pfp_url} alt="profile" />
	{/each}
	<button></button>
</div>
