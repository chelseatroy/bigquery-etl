WITH baseline AS (
  SELECT
    *
  FROM
    `moz-fx-data-shared-prod.firefox_desktop_background_update.baseline_clients_last_seen`
  WHERE
    submission_date = @submission_date
),
metrics AS (
  SELECT
    *
  FROM
    `moz-fx-data-shared-prod.firefox_desktop_background_update.metrics_clients_last_seen`
  WHERE
    submission_date = DATE_ADD(@submission_date, INTERVAL 1 DAY)
)
SELECT
  baseline.submission_date,
  baseline.normalized_channel,
  * EXCEPT (submission_date, normalized_channel)
FROM
  baseline
LEFT JOIN
  metrics
USING
  (client_id, sample_id)
