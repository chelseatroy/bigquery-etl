CREATE OR REPLACE TABLE
  `moz-fx-data-shared-prod`.stripe_external.promotion_codes_v1
PARTITION BY
  DATE(created)
CLUSTER BY
  created
AS
WITH events AS (
  SELECT
    created AS event_timestamp,
    `data`.promotion_code.*,
  FROM
    events_v1
  WHERE
    `data`.promotion_code IS NOT NULL
  UNION ALL
  SELECT
    created AS event_timestamp,
    *,
  FROM
    initial_promotion_codes_v1
)
SELECT
  id,
  ARRAY_AGG(events ORDER BY event_timestamp DESC LIMIT 1)[OFFSET(0)].* EXCEPT (id),
FROM
  events
GROUP BY
  id
