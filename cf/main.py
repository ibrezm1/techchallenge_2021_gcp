import pandas as pd
import config
import os 

"""Responds to any HTTP request.
Args:
    request (flask.Request): HTTP request object.
Returns:
    The response text or any set of values that can be turned into a
    Response object using
    `make_response <http://flask.pocoo.org/docs/1.0/api/#flask.Flask.make_response>`.
"""


btc = config.get_crypto_price(symbol = 'BTC', exchange = 'USD', start_date = '2020-01-01' , duration_days = 5)
btc.reset_index(inplace=True)
btc = btc.rename(columns = {'index':'Date'})
btc.to_gbq('BITCOIN.btc_extract_catchup', 
                project_id='zeta-yen-319702',
                chunksize=1000, 
                if_exists='replace' #if_exists='append'
                )


