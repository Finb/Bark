"""Check the sender against a local server; never send to Apple or a real watch."""

from http.server import BaseHTTPRequestHandler, HTTPServer
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
from threading import Thread


def check():
    path = Path(__file__).with_name("send-watch-tests.py")
    spec = importlib.util.spec_from_file_location("watch_sender", path)
    sender = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sender)
    with TemporaryDirectory() as directory:
        copied_script = Path(directory) / path.name
        copied_script.write_text(path.read_text(), encoding="utf-8")
        for data in (None, "/s\n{}"):
            if data is not None:
                copied_script.with_name("watch-notification-tests.json").write_text(data, encoding="utf-8")
            result = subprocess.run([sys.executable, str(copied_script), "--dry-run"], capture_output=True, text=True, timeout=10)
            assert result.returncode == 2
            assert "Cannot read watch-notification-tests.json" in result.stderr
            assert "Traceback" not in result.stderr
    cases = json.loads(path.with_name("watch-notification-tests.json").read_text())
    identifiers = [case["test"] for case in cases]
    assert len(identifiers) == len(set(identifiers))
    for case in cases:
        assert all(identifiers.index(required) < identifiers.index(case["test"]) for required in case.get("requires", []))
        assert len(sender.build_payload(case, "123456789abc", "synthetic-key")["id"].encode()) <= 64

    requests = []

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            requests.append(payload)
            if self.path == "/http-error/push":
                self.send_response(500)
                self.end_headers()
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            if self.path == "/invalid-json/push":
                self.wfile.write(b"invalid JSON")
            else:
                self.wfile.write(json.dumps({"code": 400 if self.path == "/rejected/push" else 200}).encode())

        def log_message(self, *_):
            pass

    with HTTPServer(("127.0.0.1", 0), Handler) as server:
        thread = Thread(target=server.serve_forever, daemon=True)
        thread.start()
        base = f"http://127.0.0.1:{server.server_port}"
        try:
            def run(*args):
                return subprocess.run([sys.executable, str(path), *args], capture_output=True, text=True, timeout=10)

            preview = run("--dry-run", "--only", "W31")
            assert preview.returncode == 0, preview.stderr
            assert all(identifier in preview.stdout for identifier in ("W29", "W30", "W31"))
            assert not requests
            assert run("--dry-run", "--only", "UNKNOWN").returncode == 2
            assert run("--dry-run", "--interval", "nan").returncode == 2
            assert run("--dry-run", "--interval", "-1").returncode == 2
            assert run("--server", "https://user:password@example.com", "--key", "synthetic-key").returncode == 2

            result = run("--server", base, "--key", "synthetic-key", "--only", "W31", "--interval", "0")
            assert result.returncode == 0, result.stderr
            assert len(requests) == 3
            assert requests[0]["title"] == "Server Alert"
            assert requests[0]["subtitle"] == "Production"
            assert requests[0]["body"] == "CPU usage exceeded 90% on web-01."
            assert requests[0]["level"] == "critical"
            assert len({payload["id"] for payload in requests}) == 1
            assert all(set(payload) == {"device_key", "id", "delete"} for payload in requests[1:])
            assert "synthetic-key" not in result.stdout + result.stderr
            previous_id = requests[0]["id"]
            assert run("--server", base, "--key", "synthetic-key", "--only", "W29", "--interval", "0").returncode == 0
            assert requests[-1]["id"] != previous_id

            for route in ("http-error", "invalid-json", "rejected"):
                result = run("--server", base + "/" + route, "--key", "synthetic-key", "--only", "W01", "W02", "--interval", "0")
                assert result.returncode == 1
                assert "W02 expected" not in result.stdout
                assert "synthetic-key" not in result.stdout + result.stderr
        finally:
            server.shutdown()
            thread.join(timeout=5)
    print("Passed: prerequisites, unique identifiers, silent payloads, dry runs, input validation, and server error handling.")


if __name__ == "__main__":
    check()
