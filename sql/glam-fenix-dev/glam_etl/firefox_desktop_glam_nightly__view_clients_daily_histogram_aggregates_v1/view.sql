CREATE OR REPLACE VIEW
  `glam-fenix-dev`.glam_etl.firefox_desktop_glam_nightly__view_clients_daily_histogram_aggregates_v1
AS
WITH extracted AS (
  SELECT
    *
  FROM
    `glam-fenix-dev`.glam_etl.firefox_desktop__view_clients_daily_histogram_aggregates_v1
  WHERE
    channel = 'nightly'
    AND safe.parse_datetime('%Y%m%d%H%M%S', app_build_id) IS NOT NULL
)
SELECT
  * EXCEPT (app_build_id, channel),
  `mozfun.glam.build_seconds_to_hour`(app_build_id) AS app_build_id,
  "*" AS channel
FROM
  extracted
