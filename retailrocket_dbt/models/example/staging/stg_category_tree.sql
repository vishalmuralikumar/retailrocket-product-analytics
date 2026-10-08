{{ config(materialized='view') }}

SELECT
    category_id,
    parent_id,
    source_file,
    source_row_number,
    ingested_at
FROM {{ source('retailrocket', 'category_tree') }}