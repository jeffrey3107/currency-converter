from flask import Flask, render_template, request
import requests

app = Flask(__name__)

API_URL = "http://apilayer.net/api/live"
ACCESS_KEY = "d26a7d253982c47715e2e8ba2216a62a"  # Your API key
CURRENCIES = "EUR,GBP,CAD,PLN"
SOURCE_CURRENCY = "USD"

@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        amount = float(request.form['amount'])
        target_currency = request.form['currency']
        
        # API Request to get live Forex rates
        response = requests.get(API_URL, params={
            'access_key': ACCESS_KEY,
            'currencies': CURRENCIES,
            'source': SOURCE_CURRENCY,
            'format': 1
        })
        
        data = response.json()
        if data['success']:
            rate = data['quotes'][f"USD{target_currency}"]
            converted_amount = rate * amount
            return render_template('index.html', converted_amount=converted_amount, target_currency=target_currency, amount=amount)
    
    return render_template('index.html', converted_amount=None)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
