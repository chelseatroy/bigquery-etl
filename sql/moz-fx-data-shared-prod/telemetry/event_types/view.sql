CREATE OR REPLACE VIEW
  `moz-fx-data-shared-prod.telemetry.event_types`
AS
SELECT
  *
FROM
  `moz-fx-data-shared-prod.telemetry_derived.event_types_v1`
