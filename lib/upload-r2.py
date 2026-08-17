#!/usr/bin/env python3
"""Upload install/*/packages/* to Cloudflare R2. Reads install/.env.r2 — never commit that file."""
from __future__ import annotations

import hashlib
import hmac
import http.client
import os
import ssl
import sys
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
APPS = ("codex", "claude-code", "node", "git", "vcredist")
REGION = "auto"
SERVICE = "s3"


def load_env() -> dict[str, str]:
    env = dict(os.environ)
    path = ROOT / ".env.r2"
    if path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env.setdefault(k.strip(), v.strip().strip("'").strip('"'))
    return env


def die(msg: str) -> None:
    print(f"!!  {msg}", file=sys.stderr)
    raise SystemExit(1)


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sign(key: bytes, msg: str) -> bytes:
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


def signing_key(secret: str, datestamp: str) -> bytes:
    k_date = sign(("AWS4" + secret).encode("utf-8"), datestamp)
    k_region = hmac.new(k_date, REGION.encode(), hashlib.sha256).digest()
    k_service = hmac.new(k_region, SERVICE.encode(), hashlib.sha256).digest()
    return hmac.new(k_service, b"aws4_request", hashlib.sha256).digest()


def signed_headers(
    method: str,
    host: str,
    canonical_uri: str,
    secret: str,
    access_key: str,
    extra: dict[str, str] | None = None,
    payload_hash: str = "UNSIGNED-PAYLOAD",
) -> dict[str, str]:
    now = datetime.now(timezone.utc)
    amz_date = now.strftime("%Y%m%dT%H%M%SZ")
    datestamp = now.strftime("%Y%m%d")
    headers = {
        "host": host,
        "x-amz-content-sha256": payload_hash,
        "x-amz-date": amz_date,
    }
    if extra:
        headers.update({k.lower(): v for k, v in extra.items()})
    signed = ";".join(sorted(headers))
    canonical_headers = "".join(f"{k}:{headers[k]}\n" for k in sorted(headers))
    canonical_request = "\n".join(
        [method, canonical_uri, "", canonical_headers, signed, payload_hash]
    )
    scope = f"{datestamp}/{REGION}/{SERVICE}/aws4_request"
    string_to_sign = "\n".join(
        ["AWS4-HMAC-SHA256", amz_date, scope, sha256_hex(canonical_request.encode())]
    )
    sig = hmac.new(signing_key(secret, datestamp), string_to_sign.encode(), hashlib.sha256).hexdigest()
    headers["authorization"] = (
        f"AWS4-HMAC-SHA256 Credential={access_key}/{scope}, "
        f"SignedHeaders={signed}, Signature={sig}"
    )
    return headers


def request(
    host: str,
    method: str,
    path: str,
    secret: str,
    access_key: str,
    body: bytes | None = None,
    body_file: Path | None = None,
    extra: dict[str, str] | None = None,
) -> tuple[int, bytes]:
    extra = dict(extra or {})
    length = 0
    fp = None
    if body_file is not None:
        length = body_file.stat().st_size
        extra["content-length"] = str(length)
        fp = open(body_file, "rb")
    elif body is not None:
        extra["content-length"] = str(len(body))
    headers = signed_headers(method, host, path, secret, access_key, extra=extra)
    # http.client wants header names; Host is set from connection
    send = {k: v for k, v in headers.items() if k.lower() != "host"}
    ctx = ssl.create_default_context()
    conn = http.client.HTTPSConnection(host, timeout=600, context=ctx)
    try:
        conn.request(method, path, body=fp if fp is not None else body, headers=send)
        resp = conn.getresponse()
        data = resp.read()
        return resp.status, data
    finally:
        if fp is not None:
            fp.close()
        conn.close()


def list_buckets(host: str, access_key: str, secret: str) -> list[str]:
    status, data = request(host, "GET", "/", secret, access_key)
    if status != 200:
        die(f"ListBuckets HTTP {status}: {data[:300]!r}")
    ns = {"s3": "http://doc.s3.amazonaws.com/2006-03-01"}
    root = ET.fromstring(data)
    names = [n.text for n in root.findall(".//s3:Bucket/s3:Name", ns) if n.text]
    if not names:
        names = [n.text for n in root.findall(".//{*}Name") if n.text and n.text != "true"]
        # Filter to likely bucket names (avoid Owner/ID)
        names = [n for n in names if n and " " not in n and len(n) < 64]
    return names


def put_object(
    host: str,
    bucket: str,
    key: str,
    file: Path,
    access_key: str,
    secret: str,
) -> None:
    path = "/" + urllib.parse.quote(f"{bucket}/{key}")
    extra = {
        "content-type": "application/octet-stream",
        "cache-control": "public, max-age=86400",
    }
    status, data = request(
        host, "PUT", path, secret, access_key, body_file=file, extra=extra
    )
    if status not in (200, 201):
        die(f"PUT {key} HTTP {status}: {data[:400]!r}")


def iter_packages() -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []
    for app in APPS:
        d = ROOT / app / "packages"
        if not d.is_dir():
            continue
        for f in sorted(d.iterdir()):
            if f.name.startswith("."):
                continue
            if f.is_file():
                out.append((f"{app}/{f.name}", f))
    return out


def pick_bucket(names: list[str], preferred: str) -> str:
    if preferred:
        return preferred
    if not names:
        return "install"
    for n in names:
        if n in {"install", "dl", "packages", "mkstore", "mk-install"}:
            return n
    if len(names) == 1:
        return names[0]
    print("buckets:", ", ".join(names), file=sys.stderr)
    die("多个 bucket，请在 .env.r2 里写 R2_BUCKET=")


def main() -> None:
    env = load_env()
    access = env.get("R2_ACCESS_KEY_ID") or ""
    secret = env.get("R2_SECRET_ACCESS_KEY") or ""
    account = env.get("R2_ACCOUNT_ID") or ""
    endpoint = env.get("R2_ENDPOINT") or (
        f"https://{account}.r2.cloudflarestorage.com" if account else ""
    )
    public = env.get("R2_PUBLIC_BASE") or "https://dl.mkstore.life"
    if not access or not secret or not endpoint:
        die("缺少 R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY / R2_ENDPOINT（写在 .env.r2）")
    host = urllib.parse.urlparse(endpoint).netloc
    files = iter_packages()
    if not files:
        die("没有 packages 文件")
    bucket = env.get("R2_BUCKET") or "install"
    print(f"==> bucket {bucket}  ({len(files)} files)")
    for key, path in files:
        size = path.stat().st_size
        print(f"==> 上传 {key}  ({size / 1024 / 1024:.1f} MB)")
        put_object(host, bucket, key, path, access, secret)
        print(f"    {public.rstrip('/')}/{key}")
    print("==> 完成")


if __name__ == "__main__":
    main()
