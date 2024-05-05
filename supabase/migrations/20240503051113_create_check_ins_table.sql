CREATE TABLE "check_ins"(
    "id" uuid PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "profile_id" uuid REFERENCES profiles ON DELETE CASCADE
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Check-ins are viewable by everyone." ON check_ins
    FOR SELECT
        USING (TRUE);

CREATE POLICY "Check-ins are insertable by the profile that created them." ON check_ins
    FOR INSERT
        WITH CHECK ((
            SELECT
                auth.uid()) = profile_id);

CREATE POLICY "Check-ins are updatable by the profile that created them." ON check_ins
    FOR UPDATE
        USING ((
            SELECT
                auth.uid()) = profile_id);

