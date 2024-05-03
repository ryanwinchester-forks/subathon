CREATE TABLE "checkins"(
    "id" uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "profile_id" uuid REFERENCES profiles ON DELETE CASCADE
);

ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Checkins are viewable by everyone." ON checkins
    FOR SELECT
        USING (TRUE);

CREATE POLICY "Checkins are insertable by the profile that created them." ON checkins
    FOR INSERT
        WITH CHECK ((
            SELECT
                auth.uid()) = profile_id);

CREATE POLICY "Checkins are updatable by the profile that created them." ON checkins
    FOR UPDATE
        USING ((
            SELECT
                auth.uid()) = profile_id);

