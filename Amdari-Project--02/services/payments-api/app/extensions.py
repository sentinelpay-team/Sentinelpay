"""Shared Flask extensions."""

import os
from urllib.parse import quote

from flask_limiter import Limiter
from flask_limiter.util import get_remote_address


redis_host = os.environ["REDIS_HOST"]
redis_port = os.environ.get("REDIS_PORT", "6379")
redis_auth_token = quote(
    os.environ["REDIS_AUTH_TOKEN"],
    safe="",
)

redis_scheme = os.environ.get(
    "REDIS_SCHEME",
    "rediss",
)

redis_db = os.environ.get(
    "REDIS_DB",
    "2",
)

rate_limit_storage_uri = (
    f"{redis_scheme}://:{redis_auth_token}"
    f"@{redis_host}:{redis_port}/{redis_db}"
)

limiter = Limiter(
    key_func=get_remote_address,
    storage_uri=rate_limit_storage_uri,
)