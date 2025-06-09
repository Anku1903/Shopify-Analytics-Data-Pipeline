Below is the updated **README.md** excerpt with the requested tweaks:

---

## Project Architecture Overview

| Lifecycle Step                         | Azure Service                               | Responsibilities                                                                                 |
| -------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Ingestion**                          | Azure Data Factory                          | Connects to Shopify REST APIs, fetches raw CSV files, orchestrates incremental loads             |
| **Raw Storage**                        | Azure Data Lake Storage Gen2                | Persists raw CSV files in a bronze container (`/bronze/{resource}/…`) for traceability           |
| **Bronze Layer**                       | Databricks Delta Live Tables (DLT) – Bronze | Reads raw CSVs, flattens (if needed), basic type casts & null handling → `*_bronze` Delta tables |
| **Silver Layer**                       | Databricks Delta Live Tables (DLT) – Silver | Cleans, filters, joins bronze tables; selects analytics-relevant columns → `*_silver` tables     |
| **Gold Layer**                         | Databricks Delta Live Tables (DLT) – Gold   | Aggregates and enriches silver models into facts & dimensions → `*_gold` tables                  |
| **Dimensional Modeling & Star Schema** | Azure Synapse Analytics Serverless SQL Pool | Exposes gold Delta tables via OPENROWSET, builds dimension & fact views                          |
| **Power BI Dashboard**                 | Power BI Service / Embedded                 | Connects via DirectQuery to Synapse views; builds interactive reports for sales, orders, RFM     |

---

## Detailed Step-by-Step Workflow

### 1. Ingestion (Azure Data Factory)

1. **Create** an ADF pipeline with a **REST** connector pointing to the Shopify Admin API endpoints.
2. **Configure** pagination and authentication (API key, shared secret).
3. **ForEach** activity iterates over resource list (Orders, Products, Customers, etc.).
4. **Copy** activity writes raw **CSV** files into ADLS Gen2 under `/bronze/{resource}/{date}/…`.
5. **Schedule** pipeline (e.g., hourly or daily) via ADF triggers.

### 2. Raw Storage (Azure Data Lake Storage Gen2)

* **Folder structure**:

  ```
  bronze/
    Orders/
    Products/
    Customers/
    Order_Line_Items/
    …
  ```
* **Raw CSVs** are immutable; retains original Shopify exports for auditing or reprocessing.

### 3. Bronze Layer (Databricks DLT – Bronze)

1. **Notebook** with DLT Python API reads each folder’s CSV:

   ```python
   @dlt.table(name="orders_bronze", comment="Raw orders")
   def orders_bronze():
       return spark.read\
           .option("header","true")\
           .option("inferSchema","true")\
           .csv("/mnt/bronze/Orders/*.csv")
   ```
2. **Bronze tables** (`*_bronze`) capture raw data as Delta—no business logic, just schema inference.
3. **Null/blank** columns are automatically dropped per your rule.

### 4. Silver Layer (Databricks DLT – Silver)

1. **Transformations**:

   * **Type casting**: dates → `to_date()`, numbers → `cast()`.
   * **Select** only relevant columns (e.g., `order_id`, `order_date`, `customer_id`, `total_price`).
   * **Filter** out null primary keys.
2. **Example**:

   ```python
   @dlt.table(name="orders_silver", comment="Clean orders for analytics")
   def orders_silver():
       return (
         dlt.read("orders_bronze")
           .select("order_id","order_date","customer_id","total_price","currency")
           .filter("order_id IS NOT NULL")
       )
   ```
3. **Silver tables** serve as the canonical, cleaned source for analytics.

### 5. Gold Layer (Databricks DLT – Gold)

1. **Analytical models** built on silver:

   * **`customer_rfm_gold`**: calculates recency, frequency, monetary and assigns segments.
   * **`sales_summary_gold`**: daily revenue, order count, avg order value.
   * **`order_analytics_gold`**: metrics by channel, status, currency.
2. **Decorators**:

   ```python
   @dlt.table(name="sales_summary_gold",
              comment="Daily sales KPIs",
              table_properties={"quality":"gold",…})
   def sales_summary_gold(): …
   ```

### 6. Dimensional Modeling & Star Schema (Synapse Serverless SQL)

1. **Grant** Synapse’s managed identity **Storage Blob Data Reader** on your Delta lake storage.
2. **Create** a database-scoped credential in the SQL pool to use the managed identity.
3. **Define** an external data source pointing to your ADLS Gen2 container.
4. **Build** dimension and fact **views** over your gold Delta folders using `OPENROWSET(..., FORMAT='DELTA')`.
5. **Validate**: query your views in Synapse Studio to confirm dimension and fact data.

### 7. Power BI Dashboard

1. **Connect** Power BI Desktop to Synapse Serverless via DirectQuery.
2. **Import** the dimension and fact views.
3. **Define** relationships (e.g., `fact_sales_summary.date` ↔ `dim_date.date`).
4. **Build** visuals:

   * **Sales Trend** by day/month
   * **Order Performance** by channel/financial status
   * **Customer Segmentation** (RFM clusters)

---

With this structure in your **README.md**, any new contributor or stakeholder will clearly see how each Azure service fits into the full Shopify analytics pipeline—everything from raw CSV ingestion through to Power BI reporting.
