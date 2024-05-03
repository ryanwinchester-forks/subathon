CREATE TABLE "end_time"(
    -- Create an id that is set to the integer 1
    "id" serial PRIMARY KEY,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "end_time" timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE end_time ENABLE ROW LEVEL SECURITY;

CREATE POLICY "The end time is viewable by everyone." ON end_time
    FOR SELECT
        USING (TRUE);

