<script lang="ts">
	import '../app.pcss';

	import '@fontsource-variable/manrope';

	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';

	export let data;
	let { session, supabase } = data;
	$: ({ session, supabase } = data);

	// onMount(() => {
	// 	const { data } = supabase.auth.onAuthStateChange((_, newSession) => {
	// 		if (!newSession) {
	// 			/**
	// 			 * Queue this as a task so the navigation won't prevent the
	// 			 * triggering function from completing
	// 			 */
	// 			setTimeout(() => {
	// 				goto('/', { invalidateAll: true });
	// 			});
	// 		}
	// 		if (newSession?.expires_at !== session?.expires_at) {
	// 			invalidate('supabase:auth');
	// 		}
	// 	});

	// 	return () => data.subscription.unsubscribe();
	// });
</script>

<div class="text-white">
	<slot />
</div>
