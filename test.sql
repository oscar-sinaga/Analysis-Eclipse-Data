-- 1. The total number of users who have downloaded any clips. 
-- The total number of clips downloaded. 
-- The total number of game sessions from which the downloaded clips were generated. 
SELECT
    COUNT(DISTINCT user_id) AS total_user_who_download_clips,
    COUNT(DISTINCT clip_id) AS total_clips_downloaded,
    COUNT(DISTINCT gamesession_id) AS total_gamesession_generated
FROM downloaded_clips dc;

--2. For users who purchased premium in the last 3 months: Get the number of 
-- users who purchased premium, the number of users who shared any clips, 
-- the total number of clips shared, and the total number of gamesessions from 
-- which the shared clips were generated. 

WITH premiums_users_last_3_month AS (
    SELECT user_id
    FROM premium_users
    WHERE TO_TIMESTAMP(starts_at, 'YYYY-MM-DD') >= (
        SELECT TO_TIMESTAMP(MAX(starts_at), 'YYYY-MM-DD') - INTERVAL '3 MONTH'
        FROM premium_users
    )
),
premium_summary AS (
    SELECT 
        COUNT(DISTINCT user_id) AS total_user_who_purchased_premium_last_3_months
    FROM premiums_users_last_3_month
),
shared_clips_summary AS (
    SELECT 
        COUNT(DISTINCT sc.user_id) AS number_of_user_premium_last_3_month_who_shared_clips,
        COUNT(DISTINCT sc.clip_id) AS number_of_clip_shared,
        COUNT(DISTINCT sc.gamesession_id) AS number_of_gamesession_generated_from_shared_clips
    FROM shared_clips sc
    JOIN premiums_users_last_3_month pul3m ON sc.user_id = pul3m.user_id
)

-- Gabungkan hasil keduanya (pakai CROSS JOIN karena tidak ada relasi)
SELECT 
    ps.total_user_who_purchased_premium_last_3_months,
    scs.number_of_user_premium_last_3_month_who_shared_clips,
    scs.number_of_clip_shared,
    scs.number_of_gamesession_generated_from_shared_clips
FROM premium_summary ps
CROSS JOIN shared_clips_summary scs;

-- 3. Calculate, on a weekly basis: The number of users engaged. The number of 
-- clips engaged. The total number of gamesessions from which the engaged 
-- clips were generated.

WITH engaged_clips AS (
    SELECT 
        user_id,
        clip_id,
        gamesession_id,
        TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') AS engaged_at
    FROM downloaded_clips

    UNION

    SELECT 
        user_id,
        clip_id,
        gamesession_id,
        TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') AS engaged_at
    FROM shared_clips

    UNION

    SELECT 
        user_id,
        id AS clip_id,
        gamesession_id,
        TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') AS engaged_at
    FROM clips
    WHERE clip_type_id = 3
)

SELECT
    DATE_TRUNC('week', engaged_at) AS week_start,
    COUNT(DISTINCT user_id) AS engaged_users,
    COUNT(DISTINCT clip_id) AS engaged_clips,
    COUNT(DISTINCT gamesession_id) AS engaged_gamesessions
FROM engaged_clips
GROUP BY DATE_TRUNC('week', engaged_at)
ORDER BY week_start;

