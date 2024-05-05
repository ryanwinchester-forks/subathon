export const load = async ({ locals: { supabase } }) => {
	const { data, error } = await supabase.from('checkins').select(
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
