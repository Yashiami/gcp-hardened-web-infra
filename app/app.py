import os
import sqlite3
from datetime import datetime, timezone
from flask import Flask, jsonify, request

app = Flask(__name__)
DB_PATH = os.environ.get("DB_PATH", "/app/data/app.db")


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY AUTOINCREMENT, body TEXT NOT NULL, created_at TEXT NOT NULL)"
        )


init_db()


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/data", methods=["GET", "POST"])
def data():
    if request.method == "POST":
        payload = request.get_json(silent=True) or {}
        note = payload.get("note", "").strip()
        if not note:
            return jsonify({"error": "note is required"}), 400
        now = datetime.now(timezone.utc).isoformat()
        with sqlite3.connect(DB_PATH) as conn:
            conn.execute("INSERT INTO notes (body, created_at) VALUES (?, ?)", (note, now))
        return jsonify({"saved": note, "created_at": now}), 201

    with sqlite3.connect(DB_PATH) as conn:
        rows = conn.execute("SELECT id, body, created_at FROM notes ORDER BY id DESC LIMIT 20").fetchall()
    return jsonify([{"id": r[0], "note": r[1], "created_at": r[2]} for r in rows]), 200


@app.route("/trigger-500")
def trigger_500():
    return jsonify({"error": "simulated server failure"}), 500
