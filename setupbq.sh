# gcloud auth login
# gcloud config set project <project name>
# git clone https://github.com/ibrezm1/techchallenge_2021_gcp.git
# cd techchallenge_2021_gcp

# Create and Bq location validity 1 hr only
echo "Creating BITCOIN Dataset"
bq --location=US mk -d \
--description "This is my dataset." \
BITCOIN

echo "Creating btc train table"
bq load --autodetect --source_format=CSV BITCOIN.btc_extract_2021-07-07 coin_Bitcoin.csv

echo "de-duplicating tables"
bq query --nouse_legacy_sql \
'CREATE OR REPLACE VIEW BITCOIN.v_price_data AS 
select * except(row_num) from (
SELECT
*,
ROW_NUMBER() OVER (
PARTITION BY
EXTRACT(DATE FROM Date)
ORDER BY
Date desc
) row_num
FROM
`zeta-yen-319702.BITCOIN.btc_extract_*` ) t
WHERE row_num=1' 

echo "Creating Model"
bq query --nouse_legacy_sql \
'CREATE OR REPLACE MODEL BITCOIN.ga_arima_model
OPTIONS
  (model_type = "ARIMA_PLUS",
   time_series_timestamp_col = "parsed_date",
   time_series_data_col = "Open",
   auto_arima = TRUE,
   data_frequency = "AUTO_FREQUENCY",
   decompose_time_series = TRUE
  ) AS
SELECT EXTRACT(DATE FROM Date ) AS parsed_date, Max(Open) as Open
FROM
 `BITCOIN.v_price_data` order by 1'

echo "Creating Prediction"
 bq query --nouse_legacy_sql \
 'CREATE OR REPLACE TABLE BITCOIN.PRICE_PREDICT AS  SELECT
 *
FROM
 ML.EXPLAIN_FORECAST(MODEL BITCOIN.ga_arima_model,
                     STRUCT(365 AS horizon, 0.8 AS confidence_level))'

echo "Creating Crash tables"
 bq query --nouse_legacy_sql \
'CREATE OR REPLACE TABLE BITCOIN.PRICE_CRASH as 
	select ext.*,csh.crash_open  from `BITCOIN.v_price_data` ext left outer join (Select SNo,open as crash_open from (
	Select SNo,Date,open,old_open,open-old_open as price_chg from (
	SELECT SNo, Date,Open,Lag(open,10) over (partition by Symbol  order by Date) as  old_open FROM `BITCOIN.btc_extract_*` 
	) A where old_open is not null) B 
	WHERE price_chg < -2000) csh on ext.SNo=csh.SNo     '

echo "Creating Covid tables"
bq query --nouse_legacy_sql \
'CREATE OR REPLACE TABLE BITCOIN.COVID_IMPACT as 
	select *  from `BITCOIN.btc_extract_*` WHERE Date >= "2020-03-01" and  Date <= "2021-02-28" ' 
