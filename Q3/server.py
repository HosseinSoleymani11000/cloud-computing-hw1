from __future__ import annotations

from flask import Flask, jsonify, request, abort

app = Flask(__name__)

# In-memory state.  Suitable for a demo container, **not** for multi-instance prod.
_current_status: str = "OK"


@app.get("/api/v1/status")
def get_status():
    """Return the most recently POSTed status."""
    return jsonify({"status": _current_status}), 200


@app.post("/api/v1/status")
def post_status():
    """
    Accept a JSON body like {"status": "..."} and
    atomically replace the stored status.
    """
    global _current_status

    data = request.get_json(silent=True) or {}
    new_status: str | None = data.get("status")
    if new_status is None:
        abort(400, description='Expected JSON body: {"status": "<text>"}')

    _current_status = new_status
    return jsonify({"status": _current_status}), 201


if __name__ == "__main__":  # pragma: no cover
    # The built-in dev server is fine for local hacking.
    app.run(host="0.0.0.0", port=8000)
