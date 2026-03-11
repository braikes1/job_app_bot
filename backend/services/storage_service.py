"""
Cloud file storage service (Cloudflare R2 / AWS S3).
Falls back to local storage when no credentials are configured.
"""
import logging
import os
from typing import Optional

import boto3
from botocore.exceptions import ClientError

from backend.core.config import settings

logger = logging.getLogger(__name__)

_s3_client = None


def _get_s3_client():
    global _s3_client
    if _s3_client is None and settings.S3_ACCESS_KEY_ID:
        kwargs = dict(
            aws_access_key_id=settings.S3_ACCESS_KEY_ID,
            aws_secret_access_key=settings.S3_SECRET_ACCESS_KEY,
            region_name=settings.S3_REGION,
        )
        if settings.S3_ENDPOINT_URL:
            kwargs["endpoint_url"] = settings.S3_ENDPOINT_URL
        _s3_client = boto3.client("s3", **kwargs)
    return _s3_client


async def upload_resume(file_bytes: bytes, filename: str) -> str:
    """
    Uploads resume bytes to S3/R2. Returns the public URL.
    Falls back to saving locally under data/resumes/ if no cloud is configured.
    """
    s3 = _get_s3_client()

    if s3:
        try:
            s3.put_object(
                Bucket=settings.S3_BUCKET_NAME,
                Key=filename,
                Body=file_bytes,
                ContentType="application/pdf",
            )
            if settings.S3_ENDPOINT_URL:
                url = f"{settings.S3_ENDPOINT_URL}/{settings.S3_BUCKET_NAME}/{filename}"
            else:
                url = f"https://{settings.S3_BUCKET_NAME}.s3.{settings.S3_REGION}.amazonaws.com/{filename}"
            logger.info(f"Resume uploaded to cloud: {url}")
            return url
        except ClientError as e:
            logger.error(f"S3 upload failed: {e}")

    # Local fallback
    local_dir = os.path.join("data", "resumes")
    os.makedirs(local_dir, exist_ok=True)
    safe_name = filename.replace("/", "_")
    local_path = os.path.join(local_dir, safe_name)
    with open(local_path, "wb") as f:
        f.write(file_bytes)
    logger.info(f"Resume saved locally: {local_path}")
    return f"local://{local_path}"


async def get_resume_url(filename: str) -> Optional[str]:
    """Generates a pre-signed URL for downloading a resume."""
    s3 = _get_s3_client()
    if not s3:
        return None
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.S3_BUCKET_NAME, "Key": filename},
            ExpiresIn=3600,
        )
        return url
    except ClientError as e:
        logger.error(f"Pre-signed URL generation failed: {e}")
        return None
