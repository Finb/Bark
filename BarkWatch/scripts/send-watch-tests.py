#!/usr/bin/env python3
"""Send watch notification checks. Server acceptance does not confirm watch delivery."""

import argparse
import json
import math
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import uuid4


def interval_seconds(value):
    seconds = float(value)
    if not math.isfinite(seconds) or seconds < 0:
        raise argparse.ArgumentTypeError("Interval must be finite and nonnegative.")
    return seconds


def select_cases(cases, identifiers):
    available = {case["test"] for case in cases}
    selected = set(identifiers) if identifiers is not None else available
    unknown = selected - available
    if unknown:
        raise ValueError("Unknown tests: " + ", ".join(sorted(unknown)))
    while True:
        required = selected | {
            dependency
            for case in cases if case["test"] in selected
            for dependency in case.get("requires", [])
        }
        if required == selected:
            return [case for case in cases if case["test"] in selected]
        if required - available:
            raise ValueError("Test data contains an unknown prerequisite.")
        selected = required


def build_payload(case, run_id, key):
    fields = case["payload"]
    defaults = {} if fields.get("delete") == "1" else {
        "sound": "default", "group": "Watch Option Tests", "level": "active"
    }
    payload = {**defaults, **fields, "device_key": key}
    # Restrict replacement and deletion to notifications created by this run.
    payload["id"] = f"watch-test-{run_id}-{fields.get('id', case['test'])}"
    return payload


def send_push(server, payload):
    request = Request(
        server.rstrip("/") + "/push",
        data=json.dumps(payload, ensure_ascii=False).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urlopen(request, timeout=30) as response:
            result = json.load(response)
            status = response.status
    except HTTPError as error:
        raise RuntimeError(f"Server returned HTTP {error.code}.") from None
    except (URLError, TimeoutError):
        raise RuntimeError("Could not reach the server.") from None
    except (ValueError, UnicodeError):
        raise RuntimeError("Server returned an invalid JSON response.") from None
    if status != 200 or not isinstance(result, dict) or result.get("code") != 200:
        raise RuntimeError("Server rejected the push request.")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", default=os.environ.get("BARK_SERVER_URL"), help="Server base address, or BARK_SERVER_URL.")
    parser.add_argument("--key", default=os.environ.get("BARK_DEVICE_KEY"), help="Registered watch key, or BARK_DEVICE_KEY.")
    parser.add_argument("--only", nargs="+", help="Test identifiers, such as W03 W30. Prerequisites are included automatically.")
    parser.add_argument("--interval", type=interval_seconds, default=15, help="Seconds between requests; default: 15.")
    parser.add_argument("--dry-run", action="store_true", help="Show test expectations without sending anything or requiring a key.")
    args = parser.parse_args(argv)
    data_path = Path(__file__).with_name("watch-notification-tests.json")
    try:
        cases = json.loads(data_path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        parser.error(f"Cannot read {data_path.name}: {error}")
    try:
        cases = select_cases(cases, args.only)
    except ValueError as error:
        parser.error(str(error))
    if args.dry_run:
        for case in cases:
            print(case["test"] + ": " + case["expected"])
        return 0

    server = (args.server or "").strip()
    try:
        url = urlsplit(server)
        port = url.port
        valid = url.scheme in ("http", "https") and url.hostname and not (
            url.username is not None or url.password is not None or url.query or url.fragment
        ) and (port is None or port > 0)
    except ValueError:
        valid = False
    if not valid:
        parser.error("Provide --server with an http or https server base address, without credentials, query, or fragment.")
    key = (args.key or "").strip()
    if not key:
        parser.error("Provide --key or set BARK_DEVICE_KEY to the registered watch key.")

    run_id = uuid4().hex[:12]
    print(f"Sending {len(cases)} requests, {args.interval:g} seconds apart. Confirm results on the watch.", flush=True)
    try:
        for index, case in enumerate(cases):
            if index:
                time.sleep(args.interval)
            print(case["test"] + " expected: " + case["expected"], flush=True)
            send_push(server, build_payload(case, run_id, key))
            print(case["test"] + ": server accepted; watch result unconfirmed", flush=True)
    except RuntimeError as error:
        print(f"Stopped at {case['test']}: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("\nStopped; previously accepted requests may still arrive.")
        return 130
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
