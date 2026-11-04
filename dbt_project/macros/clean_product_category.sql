{% macro get_product_category_group(column_name) %}
case
    -- Furniture
    when {{ column_name }} in (
        'furniture_decor',
        'office_furniture',
        'furniture_living_room',
        'kitchen_dining_laundry_garden_furniture',
        'furniture_bedroom',
        'furniture_mattress_and_upholstery'
    ) then 'furniture'

    -- Home & Garden
    when {{ column_name }} in (
        'bed_bath_table',
        'housewares',
        'garden_tools',
        'home_confort',
        'home_comfort_2',
        'flowers',
        'la_cuisine'
    ) then 'home_and_garden'

    -- Computers & Electronics
    when {{ column_name }} in (
        'computers_accessories',
        'telephony',
        'electronics',
        'fixed_telephony',
        'audio',
        'computers',
        'tablets_printing_image',
        'pc_gamer',
        'cine_photo'
    ) then 'computers_and_electronics'

    -- Health & Beauty
    when {{ column_name }} in (
        'health_beauty',
        'perfumery',
        'diapers_and_hygiene'
    ) then 'health_and_beauty'

    -- Fashion & Apparel
    when {{ column_name }} in (
        'fashion_bags_accessories',
        'luggage_accessories',
        'fashion_shoes',
        'fashion_male_clothing',
        'fashion_underwear_beach',
        'fashio_female_clothing',
        'fashion_sport',
        'fashion_childrens_clothes',
        'watches_gifts'
    ) then 'fashion_and_apparel'

    -- Sports & Leisure
    when {{ column_name }} in (
        'sports_leisure'
    ) then 'sports_and_leisure'

    -- Baby & Toys
    when {{ column_name }} in (
        'toys',
        'baby'
    ) then 'baby_and_toys'

    -- Auto & Parts
    when {{ column_name }} in (
        'auto'
    ) then 'auto_and_parts'

    -- Home Appliances
    when {{ column_name }} in (
        'home_appliances',
        'small_appliances',
        'air_conditioning',
        'home_appliances_2',
        'small_appliances_home_oven_and_coffee',
        'portateis_cozinha_e_preparadores_de_alimentos'
    ) then 'appliances'

    -- Construction & Tools
    when {{ column_name }} in (
        'construction_tools_construction',
        'home_construction',
        'signaling_and_security',
        'construction_tools_safety',
        'costruction_tools_garden',
        'construction_tools_lights',
        'costruction_tools_tools'
    ) then 'tools_and_construction'

    -- Stationery & Office Supplies
    when {{ column_name }} in (
        'stationery'
    ) then 'stationery_and_office'

    -- Arts, Hobbies & Party
    when {{ column_name }} in (
        'consoles_games',
        'musical_instruments',
        'art',
        'arts_and_craftmanship',
        'party_supplies',
        'christmas_supplies'
    ) then 'arts_hobbies_and_party'

    -- Pet Shop
    when {{ column_name }} in (
        'pet_shop'
    ) then 'pet_shop'

    -- Food & Beverages
    when {{ column_name }} in (
        'food_drink',
        'food',
        'drinks'
    ) then 'food_and_beverages'

    -- Books & Media
    when {{ column_name }} in (
        'books_general_interest',
        'books_technical',
        'books_imported',
        'dvds_blu_ray',
        'music',
        'cds_dvds_musicals'
    ) then 'books_and_media'

    -- Industry & Business
    when {{ column_name }} in (
        'agro_industry_and_commerce',
        'industry_commerce_and_business',
        'market_place',
        'security_and_services'
    ) then 'industry_and_business'

    -- Other or Uncategorized
    else 'other_or_uncategorized'
end
{% endmacro %}

