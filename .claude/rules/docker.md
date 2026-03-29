# Docker — Development Environment

## What uses Docker, what doesn't

| Component | Docker? | Why |
|---|---|---|
| Firebase emulators | Yes (optional) | Consistent env across machines, CI-ready |
| Flutter app | No | Needs Android emulator/device, can't run in container |
| Cloud Functions build | No | Runs on host with `npm run build:watch` |

Docker is optional for local dev — `firebase emulators:start` works without it. Use Docker when you want a reproducible, one-command emulator setup or when onboarding someone new.

## docker-compose.yml

```yaml
# docker-compose.yml (at repo root)
version: '3.8'

services:
  emulators:
    image: node:20-slim
    working_dir: /app
    command: >
      sh -c "npm install -g firebase-tools &&
             firebase emulators:start --project way2fly-dev --import=/app/emulator-data --export-on-exit"
    ports:
      - "4000:4000"   # Emulator UI
      - "9099:9099"   # Auth
      - "8080:8080"   # Firestore
      - "5001:5001"   # Functions
      - "9199:9199"   # Storage
    volumes:
      - ./firebase.json:/app/firebase.json:ro
      - ./firestore.rules:/app/firestore.rules:ro
      - ./firestore.indexes.json:/app/firestore.indexes.json:ro
      - ./storage.rules:/app/storage.rules:ro
      - ./backend/functions/lib:/app/functions/lib:ro   # built JS
      - emulator_data:/app/emulator-data
    environment:
      - FIREBASE_TOKEN=${FIREBASE_TOKEN}

volumes:
  emulator_data:
```

## Usage

```bash
# Start emulators (foreground)
docker compose up emulators

# Start in background
docker compose up -d emulators

# View logs
docker compose logs -f emulators

# Stop and remove containers
docker compose down

# Stop and wipe emulator data
docker compose down -v
```

## Ports reference

| Service | Port | URL |
|---|---|---|
| Emulator UI | 4000 | http://localhost:4000 |
| Firebase Auth | 9099 | — |
| Firestore | 8080 | — |
| Cloud Functions | 5001 | http://localhost:5001/way2fly-dev/us-central1/<fn> |
| Storage | 9199 | — |

## Flutter connects to Docker emulators
Flutter app uses the same emulator host/ports whether Docker or native:
```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

If running on a physical Android device (not emulator), replace `localhost` with your machine's LAN IP.

## CI setup
GitHub Actions uses native `firebase emulators:start` (not Docker) because the GitHub-hosted runner already has Node.js and Firebase CLI available.

```yaml
# .github/workflows/test.yml (excerpt)
- name: Start Firebase emulators
  run: firebase emulators:start --only auth,firestore,functions &
  working-directory: .
```

## Emulator data persistence
Emulator data is persisted in the `emulator_data` Docker volume (or `./emulator-data/` for native).
- `--import` on start: loads previously exported data
- `--export-on-exit`: saves data when container stops
- Wipe with `docker compose down -v` or `rm -rf ./emulator-data`
