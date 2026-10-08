SELECT *
FROM {{ ref('int_sessions') }}
WHERE session_number < 1
   OR total_event_count < 1
   OR observed_duration_seconds < 0
   OR session_end_at_utc < session_start_at_utc
   OR view_event_count < 0
   OR add_to_cart_event_count < 0
   OR purchase_event_count < 0
   OR total_event_count <>
      view_event_count
      + add_to_cart_event_count
      + purchase_event_count
   OR distinct_product_count < 1
   OR distinct_product_count > total_event_count
   OR order_count < 0
   OR order_count > purchase_event_count
   OR has_purchase <> (purchase_event_count > 0)