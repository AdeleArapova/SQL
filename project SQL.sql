CREATE DATABASE project_sql;
USE project_sql;
CREATE TABLE customer_info (
    Id_client INT NOT NULL,
    Total_amount DECIMAL(15 , 2 ),
    Gender VARCHAR(20),
    Age INT,
    Count_city INT,
    Response_communication INT,
    Communication_3month INT,
    Tenure INT,
    PRIMARY KEY (Id_client)
);
SELECT * FROM transactions_info;

CREATE TABLE transactions_info (
    date_new VARCHAR(50),
    Id_check INT,
    Id_client INT NOT NULL,
    Count_products DECIMAL(10 , 3 ),
    Sum_payments DECIMAL(15 , 2 ),
    CONSTRAINT fk_client_trans FOREIGN KEY (ID_client)
        REFERENCES customer_info (Id_client)
);
DROP TABLE IF EXISTS transactions_info;

UPDATE transactions_info 
SET 
    date_new = STR_TO_DATE(date_new, '%d/%m/%Y');
ALTER TABLE transactions_info 
MODIFY COLUMN date_new DATE;
#1. Список клиентов с непрерывной историей и метрикой 
SELECT 
    Id_client,
    SUM(Sum_payments) / COUNT(Id_check) AS avg_check,
    SUM(Sum_payments) / 12 AS monthly_avg_spending,
    COUNT(Id_check) AS total_operations
FROM
    transactions_info
WHERE
    date_new >= '2015-06-01'
        AND date_new < '2016-06-01'
GROUP BY Id_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;
#2. Анализ в разрезе месяцев
SELECT 
DATE_FORMAT(date_new, '%Y-%m') AS month,
AVG(Sum_payments) AS avg_check,
COUNT(Id_check) / COUNT(DISTINCT Id_client) AS ops_per_client,
COUNT(DISTINCT Id_client) AS active_clients,
COUNT(Id_check) * 100.0 / SUM(COUNT(Id_check)) OVER() AS ops_share_pct,
SUM(Sum_payments) * 100.0 / SUM(SUM(Sum_payments)) OVER() AS sum_share_pct
FROM transactions_info
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month;

#3. Соотношение по полу (M/F/NA) и затратам
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COALESCE(c.Gender, 'NA') AS gender,
    COUNT(DISTINCT t.Id_client) * 100.0 / SUM(COUNT(DISTINCT t.Id_client)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS gender_pct,
    SUM(t.Sum_payments) * 100.0 / SUM(SUM(t.Sum_payments)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS spend_pct
FROM transactions_info t
LEFT JOIN customer_info c ON t.Id_client = c.client_id
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month, gender;

#4. Возрастные группы (шаг 10 лет)
SELECT 
    CASE WHEN c.Age IS NULL THEN 'Unknown' 
         ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10+9) END AS age_group,
    QUARTER(t.date_new) AS qrt,
    SUM(t.Sum_payments) AS total_sum,
    COUNT(t.Id_check) AS total_ops,
    AVG(t.Sum_payments) AS q_avg_check,
    SUM(t.Sum_payments) * 100.0 / SUM(SUM(t.Sum_payments)) OVER() AS pct_of_yearly_total
FROM transactions_info t
LEFT JOIN customer_info c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY age_group, qrt;
