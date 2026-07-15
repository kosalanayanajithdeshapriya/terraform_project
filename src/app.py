import os
import platform
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template

app = Flask(__name__)

START_TIME = datetime.now(timezone.utc)


def deployment_info():
    return {
        "service": os.environ.get("K_SERVICE", "flask-app (local)"),
        "revision": os.environ.get("K_REVISION", "n/a"),
        "configuration": os.environ.get("K_CONFIGURATION", "n/a"),
        "region": os.environ.get("CLOUD_RUN_REGION", os.environ.get("REGION", "n/a")),
        "python_version": platform.python_version(),
        "started_at": START_TIME.isoformat(),
    }


@app.route("/")
def home():
    return render_template("index.html", info=deployment_info())


@app.route("/status")
def status():
    return jsonify({"status": "running"})


@app.route("/api/info")
def api_info():
    return jsonify(deployment_info())


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", debug=True, port=port)
