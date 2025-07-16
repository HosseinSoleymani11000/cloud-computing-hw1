# Assignment 2 / Problem 3: Flask Status Service
**Author**: Hossein Soleymani  
**Term**: Spring 2025

This README documents the setup and usage instructions for a minimal Flask-based status service, including the `server.py` application and its corresponding `Dockerfile`, as specified in Problem 3.

---

## What's Inside

- **`server.py`**  
  A minimal Flask application exposing the `/api/v1/status` endpoint with:
  - `GET`: Returns `{ "status": "<current>" }` with HTTP 200 OK.
  - `POST`: Accepts `{ "status": "<new>" }`, stores the new status in memory, and returns it with HTTP 201 Created.

- **`Dockerfile`**  
  Builds a lightweight container image that:
  1. Installs Flask and Gunicorn using Debian's APT package manager.
  2. Copies `server.py` into the image.
  3. Runs the application as an unprivileged user on port **8000**.

---

## Quickstart

### 1. Clone & Build

Clone the repository and build the Docker image:

```bash
git clone <this-repo-url>
cd <repo-dir>
docker build -t status-svc .
```

### 2. Run the Container

Launch the container, mapping port 8000 to the host:

```bash
docker run --rm -p 8000:8000 status-svc
```

### 3. Interact with the Service

- **Initial health check**:
  ```bash
  curl localhost:8000/api/v1/status
  ```
  - Expected output: `{"status":"OK"}`

- **Change the status**:
  ```bash
  curl -X POST \
       -H "Content-Type: application/json" \
       -d '{"status":"not OK"}' \
       localhost:8000/api/v1/status
  ```
  - Expected output: `{"status":"not OK"}`

- **Verify the status update**:
  ```bash
  curl localhost:8000/api/v1/status
  ```
  - Expected output: `{"status":"not OK"}`
