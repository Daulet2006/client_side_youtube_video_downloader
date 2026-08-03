# YouTube Downloader App

Stack:

- `backend`: FastAPI + `yt-dlp`
- `frontend`: Nuxt 3 + TypeScript
- Dockerized via `docker-compose`

## Idea

The server does not save video files locally. It only extracts YouTube metadata and direct media
stream links. The frontend then starts the download from the browser side.

## Run

```bash
docker compose up --build
```

Frontend: `http://localhost:3000`

Backend docs: `http://localhost:8000/docs`

## Notes

- Some YouTube streams may still fail in pure browser download mode because of CORS restrictions,
  expiring direct links, or YouTube-side access protections.
- In the current implementation, the app follows the "no server-side file download" requirement as
  closely as possible by not storing or downloading the media file on the backend.
- `yt-dlp==2026.7.4` is pinned because it is a published stable PyPI release as of August 2, 2026.
  If YouTube changes something and extraction starts failing later, the first thing to try is
  updating `yt-dlp` to a newer published release or switching to a pre-release/nightly build.
