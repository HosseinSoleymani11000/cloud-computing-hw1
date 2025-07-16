
## What’s inside

- **`server.py`**  
  A minimal Flask app exposing **`/api/v1/status`**, with:
  - `GET` → returns `{ "status": "<current>" }` (200 OK)
  - `POST` → accepts `{ "status": "<new>" }`, saves it in memory, returns it (201 Created)

- **`Dockerfile`**  
  Builds a slim container image that:
  1. Installs Flask & Gunicorn via Debian APT  
  2. Copies in `server.py`  
  3. Runs the app under an unprivileged user on port **8000**

---

## Quickstart

1. **Clone & build**

   ```bash
   git clone <this-repo-url>
   cd <repo-dir>
   docker build -t status-svc .

## Run it

docker run --rm -p 8000:8000 status-svc

## Talk to it 

# Initial health check

curl localhost:8000/api/v1/status
# → {"status":"OK"}

# Change the status

curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"status":"not OK"}' \
     localhost:8000/api/v1/status
# → {"status":"not OK"}

# Verify the update stuck
curl localhost:8000/api/v1/status
# → {"status":"not OK"}
