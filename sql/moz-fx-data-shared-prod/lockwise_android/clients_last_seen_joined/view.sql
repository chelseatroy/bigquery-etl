CREATE OR REPLACE VIEW
  `moz-fx-data-shared-prod.lockwise_android.clients_last_seen_joined`
AS
SELECT
  *
FROM
  `moz-fx-data-shared-prod.lockwise_android_derived.clients_last_seen_joined_v1`
