from flask import Flask, render_template
from info import Info

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html', data=Info())

@app.route('/api')
def api():
    return Info().get()

if __name__ == '__main__':
    app.run(debug=True)