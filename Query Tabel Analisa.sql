CREATE OR REPLACE TABLE `rakamin-kf-analytics-470216.kimia_farma.tabel_analisa` AS
WITH transaction AS (
  SELECT
    transaction_id,
    date,
    branch_id,
    customer_name,
    product_id,
    discount_percentage,
    rating AS rating_transaksi
  FROM `rakamin-kf-analytics-470216.kimia_farma.kf_final_transaction`
),
product AS(
  SELECT
    product_id,
    product_name,
    price
  FROM `rakamin-kf-analytics-470216.kimia_farma.kf_product`
),
branch AS(
  SELECT
    branch_id,
    branch_name,
    kota,
    provinsi,
    rating AS rating_cabang
  FROM `rakamin-kf-analytics-470216.kimia_farma.kf_kantor_cabang`
),
inventory AS(
  SELECT
    product_id,
    SUM(opname_stock) AS total_opname_stock
  FROM `rakamin-kf-analytics-470216.kimia_farma.kf_inventory`
  GROUP BY product_id
)

SELECT
  t.transaction_id,
  t.date,
  t.branch_id,
  b.branch_name,
  b.kota,
  b.provinsi,
  b.rating_cabang,
  t.customer_name,
  t.product_id,
  p.product_name,
  p.price AS actual_price,
  t.discount_percentage,

  #kasus untuk hitung persentase gross laba
  CASE
  WHEN p.price<=50000 THEN 0.10
  WHEN p.price>50000 AND p.price<=100000 THEN 0.15
  WHEN p.price>100000 AND p.price<=300000 THEN 0.20
  WHEN p.price>300000 AND p.price<=500000 THEN 0.25
  ELSE 0.3
END AS persentase_gross_laba,

# hitung netsales
p.price*(1 - (t.discount_percentage)) AS nett_sales,

#hitung netprofit=price(1-discount_percentage)*persentase_gross_laba
p.price*(1-(t.discount_percentage))*
CASE
  WHEN p.price<=50000 THEN 0.10
  WHEN p.price>50000 AND p.price<=100000 THEN 0.15
  WHEN p.price>100000 AND p.price<=300000 THEN 0.20
  WHEN p.price>300000 AND p.price<=500000 THEN 0.25
  ELSE 0.3
END AS nett_profit,
t.rating_transaksi,
i.total_opname_stock

FROM transaction t
JOIN product p ON t.product_id = p.product_id
JOIN branch b ON t.branch_id = b.branch_id
LEFT JOIN inventory i ON t.product_id = i.product_id

ORDER BY date
