import requests
import pandas as pd
import datetime
from dotenv import load_dotenv
import os

load_dotenv()  # take environment variables from .env.

def get_crypto_price(symbol, exchange, start_date = None, duration_days = None, end_date = None):
    api_key = os.getenv('ALPHA_KEY')
    api_url = f'https://www.alphavantage.co/query?function=DIGITAL_CURRENCY_DAILY&symbol={symbol}&market={exchange}&apikey={api_key}'
    raw_df = requests.get(api_url).json()
    df = pd.DataFrame(raw_df['Time Series (Digital Currency Daily)']).T
    df = df.rename(columns = {'1a. open (USD)': 'Open', '2a. high (USD)': 'High', 
                                '3a. low (USD)': 'Low', '4a. close (USD)': 'Close', '5. volume': 'Volume'})
    for i in df.columns:
        df[i] = df[i].astype(float)
    df.index = pd.to_datetime(df.index)
    df = df.iloc[::-1].drop(['1b. open (USD)', '2b. high (USD)', '3b. low (USD)', '4b. close (USD)', '6. market cap (USD)'], axis = 1)
    if start_date:
        df = df[df.index >= start_date]
    if duration_days:
        end_date = datetime.datetime.strptime(start_date, "%Y-%m-%d") +  datetime.timedelta(days=duration_days)
        end_date = end_date.strftime("%Y-%m-%d")
    if end_date:
        df = df[df.index <= end_date]
    return df
