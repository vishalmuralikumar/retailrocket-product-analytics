SELECT *
FROM {{ ref('int_product_activity') }}
WHERE total_event_count < 1
   OR view_event_count < 0
   OR add_to_cart_event_count < 0
   OR purchase_event_count < 0
   OR total_event_count <>
      view_event_count
      + add_to_cart_event_count
      + purchase_event_count
   OR interacting_visitor_count > total_event_count
   OR viewing_visitor_count > view_event_count
   OR cart_visitor_count > add_to_cart_event_count
   OR purchasing_visitor_count > purchase_event_count
   OR order_count > purchase_event_count
   OR last_seen_at_utc < first_seen_at_utc