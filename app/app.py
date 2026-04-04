"""Flask sample application - Docker Samples (Framework section)."""
import os
import secrets

from flask import Flask, jsonify

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET", secrets.token_hex(32))


@app.route("/", methods=["GET"])
def index():
    return jsonify(
        message="Hello, World!",
        status="running",
        app="pruebatecnica-banco",
    )


@app.route("/health", methods=["GET"])
def health():
    return jsonify(status="healthy"), 200


if __name__ == "__main__":
    host = os.environ.get("FLASK_HOST", "127.0.0.1")
    port = int(os.environ.get("FLASK_PORT", "8000"))
    app.run(host=host, port=port)
