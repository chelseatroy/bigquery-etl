-- Generated by bigquery_etl/events_daily/generate_queries.py
WITH sample AS (
  SELECT
    *
  FROM
    firefox_accounts_derived.funnel_events_source
),
events AS (
  SELECT
    *
  FROM
    sample
  WHERE
    submission_date = @submission_date
    OR (@submission_date IS NULL AND submission_date >= '2020-01-01')
),
joined AS (
  SELECT
    CONCAT(udf.pack_event_properties(events.extra, event_types.event_properties), index) AS index,
    events.* EXCEPT (category, event, extra)
  FROM
    events
  INNER JOIN
    firefox_accounts.event_types event_types
  USING
    (category, event)
)
SELECT
  submission_date,
  client_id,
  sample_id,
  CONCAT(STRING_AGG(index, ',' ORDER BY timestamp ASC), ',') AS events,
  -- client info
  mozfun.stats.mode_last(ARRAY_AGG(utm_term)) AS utm_term,
  mozfun.stats.mode_last(ARRAY_AGG(utm_source)) AS utm_source,
  mozfun.stats.mode_last(ARRAY_AGG(utm_medium)) AS utm_medium,
  mozfun.stats.mode_last(ARRAY_AGG(utm_campaign)) AS utm_campaign,
  mozfun.stats.mode_last(ARRAY_AGG(ua_version)) AS ua_version,
  mozfun.stats.mode_last(ARRAY_AGG(ua_browser)) AS ua_browser,
  mozfun.stats.mode_last(ARRAY_AGG(entrypoint)) AS entrypoint,
  mozfun.stats.mode_last(ARRAY_AGG(flow_id)) AS flow_id,
  mozfun.stats.mode_last(ARRAY_AGG(sync_device_count)) AS sync_device_count,
  mozfun.stats.mode_last(ARRAY_AGG(sync_active_devices_day)) AS sync_active_devices_day,
  mozfun.stats.mode_last(ARRAY_AGG(sync_active_devices_week)) AS sync_active_devices_week,
  mozfun.stats.mode_last(ARRAY_AGG(sync_active_devices_month)) AS sync_active_devices_month,
  mozfun.stats.mode_last(ARRAY_AGG(app_version)) AS app_version,
  mozfun.stats.mode_last(ARRAY_AGG(os_name)) AS os_name,
  mozfun.stats.mode_last(ARRAY_AGG(os_version)) AS os_version,
  mozfun.stats.mode_last(ARRAY_AGG(country)) AS country,
  mozfun.stats.mode_last(ARRAY_AGG(LANGUAGE)) AS language,
  -- metadata
  -- normalized fields
  -- ping info
  mozfun.map.mode_last(ARRAY_CONCAT_AGG(experiments)) AS experiments
FROM
  joined
GROUP BY
  submission_date,
  client_id,
  sample_id
