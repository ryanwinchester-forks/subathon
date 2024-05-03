CREATE TABLE "profiles"(
    "id" uuid PRIMARY KEY NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    "twitch_username" text NOT NULL UNIQUE,
    "pfp_url" text
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone." ON profiles
    FOR SELECT
        USING (TRUE);

CREATE POLICY "Users can insert their own profile." ON profiles
    FOR INSERT
        WITH CHECK ((
            SELECT
                auth.uid()) = id);

CREATE POLICY "Users can update own profile." ON profiles
    FOR UPDATE
        USING ((
            SELECT
                auth.uid()) = id);

-- When a new auth user is created by Supabase, create a profile for them
CREATE OR REPLACE FUNCTION public.handle_new_user()
    RETURNS TRIGGER
    AS $$
BEGIN
    INSERT INTO public.profiles(id, twitch_username, pfp_url)
    -- We can get the user metadata column values like this if we need them
    -- NEW.raw_user_meta_data->>'user_name', NEW.email, NEW.raw_user_meta_data->>'avatar_url'
        VALUES(NEW.id, NEW.raw_user_meta_data ->> 'name', NEW.raw_user_meta_data ->> 'avatar_url');
    RETURN new;
END;
$$
LANGUAGE plpgsql
SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE PROCEDURE public.handle_new_user();

