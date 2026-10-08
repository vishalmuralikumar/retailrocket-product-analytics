SELECT *
FROM {{ ref('stg_events') }}
WHERE
    (
        event_type = 'transaction'
        AND transaction_id IS NULL
    )
    OR
    (
        event_type IN ('view', 'addtocart')
        AND transaction_id IS NOT NULL
    )