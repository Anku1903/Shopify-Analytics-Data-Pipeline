CREATE DATABASE IF NOT EXISTS ShopifyAnalytics;


USE ShopifyAnalytics;



CREATE EXTERNAL TABLE dim_date (
    order_date DATE,
    year INT,
    month INT,
    day INT,
    quarter INT
)
WITH (
    LOCATION = 'gold/dim_date/',
    DATA_SOURCE = your_data_source,
    FILE_FORMAT = 'SynapseParquetFormat'
);


CREATE EXTERNAL TABLE dim_customer (
    customer_id BIGINT,
    customer_email STRING,
    segment STRING,
    rfm_score INT,
    recency INT,
    frequency INT,
    monetary FLOAT
)
WITH (
    LOCATION = 'gold/dim_customer/',
    DATA_SOURCE = your_data_source,
    FILE_FORMAT = 'SynapseParquetFormat'
);



CREATE EXTERNAL TABLE dim_product (
    product_id BIGINT,
    product_title STRING,
    product_type STRING,
    vendor STRING
)
WITH (
    LOCATION = 'gold/dim_product/',
    DATA_SOURCE = your_data_source,
    FILE_FORMAT = 'SynapseParquetFormat'
);



CREATE EXTERNAL TABLE dim_order_channel (
    order_source STRING,
    device_locale STRING
)
WITH (
    LOCATION = 'gold/dim_order_channel/',
    DATA_SOURCE = your_data_source,
    FILE_FORMAT = 'SynapseParquetFormat'
);



CREATE EXTERNAL TABLE fact_orders (
    order_id BIGINT,
    customer_id BIGINT,
    product_id BIGINT,
    order_date DATE,
    total_price FLOAT,
    quantity INT,
    discount FLOAT,
    tax FLOAT,
    net_order_value FLOAT,
    order_source STRING
)
WITH (
    LOCATION = 'gold/fact_orders/',
    DATA_SOURCE = your_data_source,
    FILE_FORMAT = 'SynapseParquetFormat'
);




