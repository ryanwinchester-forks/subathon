import { redirect } from '@sveltejs/kit';

import type { Actions } from '@sveltejs/kit';

export const load = async ({ locals }) => {
	const { data, error } = await locals.supabase.from('check_ins').select(
		`
            *,
            profiles ( id, twitch_username, pfp_url )
            
        `
	);

	if (error) {
		console.error(error);
		return { error };
	}

	return { CheckinsWithProfiles: data };
};

export const actions: Actions = {
	// dummydata: async ({ locals: { supabase } }) => {
	// 	const { data: userData, error: userError } = await supabase
	// 		.from('profiles')
	// 		.select('*')
	// 		.single();

	// 	if (userError) {
	// 		console.error(userError);
	// 		return { userError };
	// 	}

	// 	// Generate a UUID

	// 	const payload = [
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: new Date().toISOString(),
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-04-04 21:38:12+00',
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-04-03 21:38:12+00',
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-04-02 21:38:12+00',
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-03-25 21:38:12+00',
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-04-02 21:38:12+00',
	// 			profile_id: userData.id
	// 		},
	// 		{
	// 			id: crypto.randomUUID(),
	// 			created_at: '2024-04-01 21:38:12+00',
	// 			profile_id: userData.id
	// 		}
	// 	];

	// 	const { error } = await supabase.from('check_ins').insert(payload);

	// 	if (error) {
	// 		console.error(error);
	// 		return { error };
	// 	}
	// },
	login: async ({ locals: { supabase } }) => {
		const { data, error } = await supabase.auth.signInWithOAuth({
			provider: 'twitch',
			options: {
				redirectTo: 'http://localhost:5173/auth/callback',
				scopes: 'channel:read:subscriptions bits:read'
			}
		});
		if (error) {
			console.error(error);
			return redirect(303, '/auth/error');
		} else {
			return redirect(303, data.url);
		}
	},
	check_in: async ({ locals: { session, supabase } }) => {
		const currentDate = new Date();
		const startDate = new Date(
			currentDate.getFullYear(),
			currentDate.getMonth(),
			currentDate.getDate(),
			0,
			0,
			0
		);
		const formattedStartDate = startDate.toISOString();

		console.log(formattedStartDate);

		// Let's check if the user already has a check-in for today
		const { data: checkInsData, error: checkInsError } = await supabase
			.from('check_ins')
			.select('*')
			.eq('profile_id', session?.user?.id)
			.gte('created_at', formattedStartDate);

		if (checkInsError) {
			console.error(checkInsError);
			return { checkInsError };
		}

		if (checkInsData.length > 0) {
			console.log("Homie, you've already checked in today!");
			return { error: "You've already checked in today homie! 💖" };
		}

		const { error } = await supabase.from('check_ins').insert({
			created_at: new Date().toISOString(),
			profile_id: session?.user?.id
		});

		if (error) {
			console.error(error);
			return { error };
		}

		return { success: true };
	}
};
