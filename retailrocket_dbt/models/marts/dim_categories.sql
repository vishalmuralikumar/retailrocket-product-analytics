{{ config(materialized='table') }}

WITH category_ids AS (
    SELECT category_id
    FROM {{ ref('stg_category_tree') }}

    UNION

    SELECT category_id
    FROM {{ ref('fct_events') }}
    WHERE category_id IS NOT NULL
)

SELECT
    categories.category_id,
    'Category ' || TO_VARCHAR(categories.category_id) AS category_label,
    tree.parent_id AS parent_category_id,
    tree.category_id IS NOT NULL AS exists_in_category_tree
FROM category_ids AS categories
LEFT JOIN {{ ref('stg_category_tree') }} AS tree
    ON categories.category_id = tree.category_id