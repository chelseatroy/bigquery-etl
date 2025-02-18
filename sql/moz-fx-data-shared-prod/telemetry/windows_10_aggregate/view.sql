CREATE OR REPLACE VIEW
  `moz-fx-data-shared-prod.telemetry.windows_10_aggregate` AS
WITH
  aggregated AS (
  SELECT
    os AS name,
    os_version AS version,
    windows_build_number AS build_number,
    CAST(windows_ubr AS STRING) AS ubr,
    CASE
    WHEN windows_build_number <= 17134 THEN 'Win10 <1809'
    WHEN windows_build_number <= 17763 THEN 'Win10 1809'
    WHEN windows_build_number <= 18362 THEN 'Win10 1903'
    WHEN windows_build_number <= 18363 THEN 'Win10 1909'
    WHEN windows_build_number <= 19041 THEN 'Win10 2004'
    WHEN windows_build_number <= 19042 THEN 'Win10 20H2'
    WHEN windows_build_number <= 19043 THEN 'Win10 21H1'
    WHEN windows_build_number <= 19044 THEN 'Win10 21H2'
    WHEN windows_build_number < 22000 THEN 'Win10 Insider'
    WHEN windows_build_number = 22000 THEN 'Win11 21H2'
    WHEN windows_build_number > 22000 THEN 'Win11 Insider'
    ELSE NULL
    END AS build_group,
    SPLIT(app_version, ".")[OFFSET(0)] AS ff_build_version,
    normalized_channel,
    COUNT(*) AS `count`
  FROM
    `moz-fx-data-shared-prod.telemetry.clients_daily`
  WHERE
    submission_date > DATE_SUB(CURRENT_DATE, INTERVAL 28 DAY)
    AND os = 'Windows_NT'
    AND STARTS_WITH(os_version, '10')
    AND SAFE_CAST(SPLIT(app_version, ".")[OFFSET(0)] AS INT64) >= 47
    AND sample_id = 42
  GROUP BY
    name,
    version,
    build_number,
    ubr,
    build_group,
    ff_build_version,
    normalized_channel),
  total AS (
  SELECT
    SUM(count) total_obs
  FROM
    aggregated)
SELECT
  *
FROM
  aggregated
CROSS JOIN
  total
