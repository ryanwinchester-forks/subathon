<script lang="ts">
	import { onMount } from 'svelte';

	export let data;
	let { session, supabase } = data;
	$: ({ session, user } = data);

	console.log('page session', session);

	let twitchReady: boolean = false;

	onMount(() => {
		twitchReady = true;
	});
</script>

<div class="h-3 w-full bg-pink-500"></div>
<div class="h-3 w-full bg-violet-700"></div>
<div class="h-3 w-full bg-blue-900"></div>

{#if session?.user}
	<p class="text-3xl text-white">{session}</p>
{:else}
	<p>Not logged in</p>
{/if}

<div class="min-w-screen flex min-h-screen flex-col items-center bg-neutral-950 p-8">
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
</div>
