# Create a simple, lightweight app.py

from flask import Flask, request, render_template, jsonify
import requests
import os
from datetime import datetime

app = Flask(__name__)

def init_db():
    """Simple database initialization placeholder"""
    pass

def get_exchange_rate(from_currency, to_currency):
    """Get exchange rate with simple fallback"""
    try:
        # Simple API call with fallback
        url = f"https://api.exchangerate-api.com/v4/latest/{from_currency}"
        response = requests.get(url, timeout=5)
        data = response.json()
        return data['rates'].get(to_currency, 1.0)
    except:
        # Simple fallback rates for demo
        rates = {'EUR': 0.85, 'GBP': 0.73, 'CAD': 1.25, 'PLN': 4.0}
        return rates.get(to_currency, 1.0)

@app.route('/')
def index():
    """Main page"""
    return render_template('index.html')

@app.route('/', methods=['POST'])
def convert():
    """Handle currency conversion"""
    try:
        amount_str = request.form.get('amount', '').strip()
        to_currency = request.form.get('currency', '').strip().upper()
        
        if not amount_str or not to_currency:
            return render_template('index.html', error="Please fill in all fields")
        
        try:
            amount = float(amount_str)
            if amount <= 0:
                return render_template('index.html', error="Amount must be positive")
            if amount > 1000000:
                return render_template('index.html', error="Amount too large")
        except ValueError:
            return render_template('index.html', error="Please enter a valid amount")
        
        valid_currencies = ['EUR', 'GBP', 'CAD', 'PLN']
        if to_currency not in valid_currencies:
            return render_template('index.html', error="Invalid currency selected")
        
        # Get rate and convert
        rate = get_exchange_rate('USD', to_currency)
        converted_amount = amount * rate
        
        result = f"{amount} USD = {converted_amount:.2f} {to_currency}"
        return render_template('index.html', result=result)
        
    except Exception as e:
        return render_template('index.html', error="Conversion error occurred")

@app.route('/health')
def health():
    """Health check for K8s"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

@app.route('/metrics')
def metrics():
    """Simple metrics endpoint"""
    return "# Demo metrics\napp_status 1\n", 200, {'Content-Type': 'text/plain'}

@app.route('/api/trades')
def get_trades():
    """Simple trades API"""
    return jsonify([])

@app.route('/api/stats')
def get_stats():
    """Simple stats API"""
    return jsonify({
        'total_conversions': 0,
        'most_popular_currency': 'EUR',
        'today_conversions': 0
    })

if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)