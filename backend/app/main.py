from __future__ import annotations

from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, HttpUrl
from yt_dlp import YoutubeDL
from yt_dlp.utils import DownloadError


class VideoRequest(BaseModel):
    url: HttpUrl


class VideoFormat(BaseModel):
    format_id: str
    ext: str | None = None
    quality: str
    resolution: str | None = None
    fps: float | None = None
    audio_bitrate: int | None = None
    filesize: int | None = None
    direct_url: str
    has_video: bool
    has_audio: bool


class VideoInfoResponse(BaseModel):
    title: str
    duration: int | None = None
    thumbnail: str | None = None
    webpage_url: str
    formats: list[VideoFormat] = Field(default_factory=list)


YDL_OPTS: dict[str, Any] = {
    "quiet": True,
    "skip_download": True,
    "noplaylist": True,
    "no_warnings": True,
    "extractor_args": {
        "youtube": {
            "player_client": ["web"],
            "po_token": ["web+http://po_token_provider:8080/"]
        }
    },
}

app = FastAPI(
    title="YouTube Direct Downloader API",
    version="1.0.0",
    description=(
        "Extracts YouTube metadata and direct media URLs without downloading files on the server."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def normalize_formats(raw_formats: list[dict[str, Any]]) -> list[VideoFormat]:
    normalized: list[VideoFormat] = []

    for item in raw_formats:
        direct_url = item.get("url")
        if not direct_url:
            continue

        vcodec = item.get("vcodec")
        acodec = item.get("acodec")
        height = item.get("height")
        fps = item.get("fps")
        ext = item.get("ext")
        format_note = item.get("format_note")
        abr = item.get("abr")
        resolution = f"{height}p" if height else None

        quality_parts = [
            resolution,
            f"{fps}fps" if fps else None,
            f"{int(abr)}kbps" if abr else None,
            ext,
            format_note,
        ]
        quality = " ".join(part for part in quality_parts if part) or item.get("format_id", "unknown")

        normalized.append(
            VideoFormat(
                format_id=str(item.get("format_id", "unknown")),
                ext=ext,
                quality=quality,
                resolution=resolution,
                fps=float(fps) if fps is not None else None,
                audio_bitrate=int(abr) if abr else None,
                filesize=item.get("filesize") or item.get("filesize_approx"),
                direct_url=direct_url,
                has_video=bool(vcodec and vcodec != "none"),
                has_audio=bool(acodec and acodec != "none"),
            )
        )

    normalized.sort(
        key=lambda fmt: (
            not (fmt.has_video and fmt.has_audio),
            not fmt.has_video,
            -(fmt.fps or 0),
            fmt.filesize is None,
            -(fmt.filesize or 0),
        )
    )
    return normalized


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/video-info", response_model=VideoInfoResponse)
def get_video_info(payload: VideoRequest) -> VideoInfoResponse:
    try:
        with YoutubeDL(YDL_OPTS) as ydl:
            info = ydl.extract_info(str(payload.url), download=False)
    except DownloadError as exc:
        raise HTTPException(status_code=400, detail=f"Failed to extract video info: {exc}") from exc
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=500, detail="Unexpected extraction error.") from exc

    if not info:
        raise HTTPException(status_code=404, detail="Video info not found.")

    return VideoInfoResponse(
        title=info.get("title") or "Untitled video",
        duration=info.get("duration"),
        thumbnail=info.get("thumbnail"),
        webpage_url=info.get("webpage_url") or str(payload.url),
        formats=normalize_formats(info.get("formats") or []),
    )
