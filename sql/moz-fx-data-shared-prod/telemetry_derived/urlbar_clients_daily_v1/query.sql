CREATE TEMP FUNCTION one_index(x ANY TYPE) AS (
  CAST(IF(SAFE_CAST(x AS INT64) < 0, SAFE_CAST(x AS INT64), SAFE_CAST(x AS INT64) + 1) AS STRING)
);

CREATE TEMP FUNCTION one_index_struct(x STRUCT<k STRING, v INT64>) AS (
  STRUCT(one_index(x.k) AS key, x.v AS value)
);

CREATE TEMP FUNCTION one_index_array(x ARRAY<STRUCT<k STRING, v INT64>>) AS (
  ARRAY(SELECT one_index_struct(e) FROM UNNEST(x) AS e)
);

WITH combined_urlbar_picked AS (
  SELECT
    submission_date,
    client_id,
    default_search_engine,
    app_version,
    normalized_channel,
    locale,
    user_pref_browser_search_region AS search_region,
    SAFE_CAST(user_pref_browser_search_suggest_enabled AS BOOL) AS suggest_enabled,
    SAFE_CAST(user_pref_browser_widget_in_navbar AS BOOL) AS in_navbar,
    SAFE_CAST(user_pref_browser_urlbar_suggest_searches AS BOOL) AS suggest_searches,
    SAFE_CAST(
      user_pref_browser_urlbar_show_search_suggestions_first AS BOOL
    ) AS show_search_suggestions_first,
    [
      STRUCT(
        "autofill" AS type,
        one_index_array(scalar_parent_urlbar_picked_autofill_sum) AS position
      ),
      STRUCT(
        "bookmark" AS type,
        one_index_array(scalar_parent_urlbar_picked_bookmark_sum) AS position
      ),
      STRUCT(
        "dynamic" AS type,
        one_index_array(scalar_parent_urlbar_picked_dynamic_sum) AS position
      ),
      STRUCT(
        "extension" AS type,
        one_index_array(scalar_parent_urlbar_picked_extension_sum) AS position
      ),
      STRUCT(
        "formhistory" AS type,
        one_index_array(scalar_parent_urlbar_picked_formhistory_sum) AS position
      ),
      STRUCT(
        "history" AS type,
        one_index_array(scalar_parent_urlbar_picked_history_sum) AS position
      ),
      STRUCT(
        "keyword" AS type,
        one_index_array(scalar_parent_urlbar_picked_keyword_sum) AS position
      ),
      STRUCT(
        "remotetab" AS type,
        one_index_array(scalar_parent_urlbar_picked_remotetab_sum) AS position
      ),
      STRUCT(
        "searchengine" AS type,
        one_index_array(scalar_parent_urlbar_picked_searchengine_sum) AS position
      ),
      STRUCT(
        "searchsuggestion" AS type,
        one_index_array(scalar_parent_urlbar_picked_searchsuggestion_sum) AS position
      ),
      STRUCT(
        "switchtab" AS type,
        one_index_array(scalar_parent_urlbar_picked_switchtab_sum) AS position
      ),
      STRUCT(
        "tabtosearch" AS type,
        one_index_array(scalar_parent_urlbar_picked_tabtosearch_sum) AS position
      ),
      STRUCT("tip" AS type, one_index_array(scalar_parent_urlbar_picked_tip_sum) AS position),
      STRUCT(
        "topsite" AS type,
        one_index_array(scalar_parent_urlbar_picked_topsite_sum) AS position
      ),
      STRUCT(
        "unknown" AS type,
        one_index_array(scalar_parent_urlbar_picked_unknown_sum) AS position
      ),
      STRUCT(
        "visiturl" AS type,
        one_index_array(scalar_parent_urlbar_picked_visiturl_sum) AS position
      )
    ] AS urlbar_picked_by_type_by_position
  FROM
    telemetry.clients_daily
  WHERE
    submission_date = @submission_date
),
count_picked AS (
  SELECT
    submission_date,
    client_id,
    COALESCE(SUM(position.value), 0) AS count_picked_total,
    mozfun.map.sum(ARRAY_AGG(STRUCT(type AS key, position.value AS value))) AS count_picked_by_type,
    mozfun.map.sum(
      ARRAY_AGG(STRUCT(one_index(position.key) AS key, position.value AS value))
    ) AS count_picked_by_position
  FROM
    combined_urlbar_picked
  CROSS JOIN
    UNNEST(urlbar_picked_by_type_by_position) AS urlbar_picked
  CROSS JOIN
    UNNEST(position) AS position
  GROUP BY
    submission_date,
    client_id
)
SELECT
  submission_date,
  client_id,
  default_search_engine,
  app_version,
  normalized_channel,
  locale,
  search_region,
  suggest_enabled,
  in_navbar,
  suggest_searches,
  show_search_suggestions_first,
  count_picked_total,
  count_picked_by_type,
  count_picked_by_position,
  urlbar_picked_by_type_by_position,
FROM
  combined_urlbar_picked
FULL OUTER JOIN
  count_picked
USING
  (submission_date, client_id)
