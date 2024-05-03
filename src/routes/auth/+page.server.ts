import { redirect } from '@sveltejs/kit';

import type { Actions } from './$types';

export const actions: Actions = {
	signup: async ({ request, locals: { supabase } }) => {
		const formData = await request.formData();
		const email = formData.get('email') as string;
		const password = formData.get('password') as string;

		const { error } = await supabase.auth.signUp({ email, password });
		if (error) {
			console.error(error);
			return redirect(303, '/auth/error');
		} else {
			return redirect(303, '/');
		}
	},
	login: async ({ request, locals: { supabase } }) => {
		const { data, error } = await supabase.auth.signInWithOAuth({
			provider: 'twitch',
			options: {
				redirectTo: 'localhost:5173/auth/confirm',
				scopes: 'channel:read:subscriptions bits:read'
			}
		});

		if (error) {
			console.error(error);
			return redirect(303, '/auth/error');
		} else {
			return redirect(303, data.url);
		}
	}
};
