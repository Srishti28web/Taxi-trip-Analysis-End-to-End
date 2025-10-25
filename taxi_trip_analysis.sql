CREATE DATABASE p2_taxi_trip_db;


USE p2_taxi_trip_db;

CREATE TABLE taxi_trips
(
    trip_id INT PRIMARY KEY,
    pickup_datetime TIMESTAMP,
    dropoff_datetime TIMESTAMP,
    passenger_count INT,
    trip_distance FLOAT,
    pickup_location VARCHAR(50),
    dropoff_location VARCHAR(50),
    fare_amount FLOAT,
    tip_amount FLOAT,
    total_amount FLOAT,
    payment_type VARCHAR(20),
    driver_id INT
);

-- Why: Before analysis, we must check dataset h(nulls, invalid data, outliers).

-- Step 1: Count total rows (to understand dataset size)
SELECT COUNT(*) FROM taxi_trips;

-- Step 2: Check for missing values
SELECT * FROM taxi_trips
WHERE pickup_datetime IS NULL OR dropoff_datetime IS NULL
   OR passenger_count IS NULL OR trip_distance IS NULL
   OR fare_amount IS NULL OR total_amount IS NULL;

-- Step 3: Remove invalid records (negative fare or distance, zero passengers)
DELETE FROM taxi_trips
WHERE fare_amount <= 0 OR trip_distance <= 0 OR passenger_count <= 0;

-- Step 4: Outlier detection (very long trips or huge fares may be errors)
SELECT *
FROM taxi_trips
WHERE trip_distance > 50 OR total_amount > 500;

-- Step 5: Data consistency check (fare + tip should ≈ total)
SELECT *
FROM taxi_trips
WHERE ROUND(fare_amount + tip_amount,2) <> ROUND(total_amount,2);


-- Why: EDA helps us get a “feel” of the dataset before jumping into insights.

-- Total trips
SELECT COUNT(*) AS total_trips FROM taxi_trips;

-- Unique drivers and zones 
SELECT COUNT(DISTINCT driver_id) AS total_drivers,
       COUNT(DISTINCT pickup_location) AS pickup_locations,
       COUNT(DISTINCT dropoff_location) AS dropoff_locations
FROM taxi_trips;

-- Average fare, tip, and distance →  figures for comparison
SELECT ROUND(AVG(fare_amount),2) AS avg_fare,
       ROUND(AVG(tip_amount),2) AS avg_tip,
       ROUND(AVG(trip_distance),2) AS avg_distance
FROM taxi_trips;



-- Why: Businesses want to know when revenue is high or low → plan promotions, driver availability.

-- Q1: Monthly revenue trend
SELECT DATE_FORMAT(pickup_datetime, '%Y-%m') AS month,
       SUM(total_amount) AS monthly_revenue
FROM taxi_trips
GROUP BY month
ORDER BY month;

-- Why: Understanding demand by time of day helps optimize driver shifts.
-- Q2: Peak booking hours
SELECT HOUR(pickup_datetime) AS hour,
       COUNT(*) AS trip_count
FROM taxi_trips
GROUP BY hour
ORDER BY trip_count DESC;

-- Why: Company can identify top performers and reward them.
-- Q3: Top 5 earning drivers
SELECT driver_id, SUM(total_amount) AS total_earnings
FROM taxi_trips
GROUP BY driver_id
ORDER BY total_earnings DESC
LIMIT 5;

-- Why: Checking average distance per driver to spot unusual driving patterns (fraud or inefficiency).
-- Q4: Average trip distance per driver
SELECT driver_id, ROUND(AVG(trip_distance),2) AS avg_distance
FROM taxi_trips
GROUP BY driver_id;



-- Why: Popular pickup zones tell us where demand originates → good for surge pricing.
-- Q5: Most popular pickup zones
SELECT pickup_location, COUNT(*) AS trips
FROM taxi_trips
GROUP BY pickup_location
ORDER BY trips DESC
LIMIT 5;

-- Why: Passenger counts show if trips are solo or group-based → useful for service design.
-- Q6: Passenger count distribution
SELECT passenger_count, COUNT(*) AS total_trips
FROM taxi_trips
GROUP BY passenger_count
ORDER BY passenger_count;



-- Why: Companies must know which payment modes people prefer → plan promotions accordingly.
-- Q7: Revenue by payment type
SELECT payment_type, SUM(total_amount) AS total_revenue
FROM taxi_trips
GROUP BY payment_type;

-- Why: Tipping habits differ by payment → helps in designing incentive schemes.
-- Q8: Avg tip percentage by payment method
SELECT payment_type,
       ROUND(AVG(tip_amount/fare_amount*100),2) AS avg_tip_pct
FROM taxi_trips
WHERE fare_amount > 0
GROUP BY payment_type;



-- Why: Identifying high-traffic routes helps optimize pricing and driver deployment.
-- Q9: Top 5 busiest routes
SELECT pickup_location , dropoff_location, COUNT(*) AS total_trips
FROM taxi_trips
GROUP BY pickup_location , dropoff_location
ORDER BY total_trips DESC
LIMIT 5;

-- Why: Highest revenue routes indicate premium demand areas.
-- Q10: Highest revenue routes
SELECT pickup_location, dropoff_location, SUM(total_amount) AS revenue
FROM taxi_trips
GROUP BY pickup_location, dropoff_location
ORDER BY revenue DESC
LIMIT 3;



-- Why: Demand varies between weekdays vs weekends → helps adjust driver supply.
-- Q11: Weekend vs Weekday revenue
SELECT CASE 
            WHEN DAYOFWEEK(pickup_datetime) IN (1,7) THEN 'Weekend'
            ELSE 'Weekday' 
       END AS day_type,
       SUM(total_amount) AS total_revenue
FROM taxi_trips
GROUP BY day_type;

-- Why: Special events (like New Year’s Eve) create demand spikes.
-- Q12: Trips on New Year’s Eve
SELECT COUNT(*) AS trips, SUM(total_amount) AS revenue
FROM taxi_trips
WHERE DATE(pickup_datetime) = '2022-12-31';



