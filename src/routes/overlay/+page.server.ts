export const load = async ({ locals: { supabase } }) => {
	const { data, error } = await supabase.from('end_time').select('*').single();

	if (error) {
		console.error(error);
		return { error };
	}
	return { end_time: data };
};
