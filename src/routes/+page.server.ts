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
	dummydata: async ({ locals: { supabase } }) => {
		const { data: userData, error: userError } = await supabase
			.from('profiles')
			.select('*')
			.single();

		if (userError) {
			console.error(userError);
			return { userError };
		}

		// Generate a UUID

		const payload = [
			{
				id: crypto.randomUUID(),
				created_at: '2024-04-04 21:38:12+00',
				profile_id: userData.id
			},
			{
				id: crypto.randomUUID(),
				created_at: '2024-04-03 21:38:12+00',
				profile_id: userData.id
			},
			{
				id: crypto.randomUUID(),
				created_at: '2024-04-02 21:38:12+00',
				profile_id: userData.id
			},
			{
				id: crypto.randomUUID(),
				created_at: '2024-03-25 21:38:12+00',
				profile_id: userData.id
			},
			{
				id: crypto.randomUUID(),
				created_at: '2024-04-02 21:38:12+00',
				profile_id: userData.id
			},
			{
				id: crypto.randomUUID(),
				created_at: '2024-04-01 21:38:12+00',
				profile_id: userData.id
			}
		];

		const { error } = await supabase.from('check_ins').insert(payload);

		if (error) {
			console.error(error);
			return { error };
		}
	}
};
