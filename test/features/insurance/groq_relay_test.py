"""Run with python -m unittest discover -s test/features/insurance -p groq_relay_test.py."""
import importlib.util
import http.client
import io
import json
import os
from pathlib import Path
import unittest
import threading
import tempfile
from unittest.mock import patch

path = Path(__file__).resolve().parents[3] / "lib/features/insurance/tool/groq_relay.py"
spec = importlib.util.spec_from_file_location("insurance_groq_relay", path)
relay = importlib.util.module_from_spec(spec)
spec.loader.exec_module(relay)


class RelayTest(unittest.TestCase):
    def test_load_local_key_prefers_environment_and_reads_ignored_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            fake_script = Path(tmp) / "groq_relay.py"
            (Path(tmp) / ".env").write_text("GROQ_API_KEY=local-test-key\n", encoding="utf-8")
            with patch.object(relay, "__file__", str(fake_script)), patch.dict(os.environ, {}, clear=True):
                relay.load_local_key()
                self.assertEqual(os.environ["GROQ_API_KEY"], "local-test-key")
                os.environ["GROQ_API_KEY"] = "environment-test-key"
                relay.load_local_key()
                self.assertEqual(os.environ["GROQ_API_KEY"], "environment-test-key")

    def test_refuses_unapproved_or_invalid_fields(self):
        for facts in [
            {"status": "SUBMITTED", "amount_tnd": 1, "name": "Private"},
            {"status": "PAID", "amount_tnd": -1},
            {"status": "OTHER", "amount_tnd": 1},
            {"status": "SUBMITTED", "amount_tnd": 1, "decision_reason": "Private"},
            {"status": "WAITING_DOCUMENTS", "amount_tnd": 1, "requested_documents": "Private"},
        ]:
            with self.subTest(facts=facts), self.assertRaises(ValueError):
                relay.validate(facts)

    def test_groq_request_uses_environment_key_and_only_allowed_facts(self):
        facts = {"status": "WAITING_DOCUMENTS", "amount_tnd": 50}
        response = io.BytesIO(json.dumps({"choices": [{"message": {"content": "Joignez la facture."}}]}).encode())
        with patch.dict(os.environ, {"GROQ_MODEL": "test-model"}), patch.object(relay.urllib.request, "urlopen", return_value=response) as send:
            self.assertEqual(relay.generate(facts, "test-key"), "Joignez la facture.")
        request = send.call_args.args[0]
        self.assertEqual(request.full_url, relay.GROQ_URL)
        self.assertEqual(request.get_header("Authorization"), "Bearer test-key")
        self.assertEqual(request.get_header("User-agent"), "MediLink-Insurance/1.0")
        payload = json.loads(request.data)
        self.assertEqual(payload["model"], "test-model")
        self.assertEqual(json.loads(payload["messages"][1]["content"]), facts)
        self.assertNotIn("test-key", json.dumps(payload))

    def test_refuses_missing_key(self):
        with self.assertRaises(RuntimeError):
            relay.generate({"status": "SUBMITTED", "amount_tnd": 10}, "")

    def test_document_task_requires_only_the_consented_text(self):
        valid = {"task": "documents", "instruction": "Une facture acquittée."}
        self.assertEqual(relay.validate(valid), valid)
        for invalid in [
            {**valid, "name": "private"},
            {"task": "documents", "instruction": " "},
            {"task": "documents", "instruction": "x" * 1001},
        ]:
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                relay.validate(invalid)
        response = io.BytesIO(json.dumps({"choices": [{"message": {"content": "Une facture est demandée."}}]}).encode())
        with patch.object(relay.urllib.request, "urlopen", return_value=response) as send:
            relay.generate(valid, "test-key")
        payload = json.loads(send.call_args.args[0].data)
        self.assertEqual(payload["messages"][0]["content"], relay.DOCUMENT_SYSTEM)
        self.assertEqual(json.loads(payload["messages"][1]["content"]), valid)

    def test_comparison_uses_only_fixed_demo_catalogue_and_bounded_inputs(self):
        valid = {"task": "compare", "offer_id": "demo_balance", "budget": 60, "priorities": ["consultations", "dental"]}
        self.assertEqual(relay.validate(valid), valid)
        for invalid in [
            {**valid, "offer_id": "real-insurer"},
            {**valid, "offer_id": []},
            {**valid, "budget": 10},
            {**valid, "priorities": ["secret free text"]},
            {**valid, "priorities": ["dental", "dental"]},
            {**valid, "identity": "private"},
        ]:
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                relay.validate(invalid)
        response = io.BytesIO(json.dumps({"choices": [{"message": {"content": "Offre fictive."}}]}).encode())
        with patch.object(relay.urllib.request, "urlopen", return_value=response) as send:
            relay.generate(valid, "test-key")
        payload = json.loads(send.call_args.args[0].data)
        facts = json.loads(payload["messages"][1]["content"])
        self.assertEqual(facts["offer"], relay.DEMO_OFFERS["demo_balance"])
        self.assertEqual(facts["budget_tnd"], 60)
        self.assertEqual(payload["messages"][0]["content"], relay.COMPARISON_SYSTEM)

    def test_default_model_is_the_supported_groq_model(self):
        response = io.BytesIO(json.dumps({"choices": [{"message": {"content": "À examiner."}}]}).encode())
        with patch.dict(os.environ, {}, clear=True), patch.object(relay.urllib.request, "urlopen", return_value=response) as send:
            self.assertEqual(relay.generate({"status": "SUBMITTED", "amount_tnd": 1}, "test-key"), "À examiner.")
        self.assertEqual(json.loads(send.call_args.args[0].data)["model"], "openai/gpt-oss-20b")

    def test_http_consent_payload_and_foreign_browser_origin(self):
        server = relay.ThreadingHTTPServer(("127.0.0.1", 0), relay.Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        conn = http.client.HTTPConnection("127.0.0.1", server.server_port, timeout=5)
        self.addCleanup(conn.close)
        body = json.dumps({"status": "SUBMITTED", "amount_tnd": 50})
        with patch.object(relay, "generate", return_value="Dossier à examiner.") as mock:
            conn.request("POST", "/explain", body, {"Content-Type": "application/json", "Origin": "https://outside.example"})
            self.assertEqual(conn.getresponse().status, 400)
            mock.assert_not_called()
            conn.close()
            conn.request("POST", "/explain", body, {"Content-Type": "application/json", "Origin": "http://localhost:3000"})
            response = conn.getresponse()
            self.assertEqual(response.status, 200)
            self.assertEqual(response.getheader("Access-Control-Allow-Origin"), "http://localhost:3000")
            self.assertEqual(json.load(response)["explanation"], "Dossier à examiner.")
            mock.assert_called_once()

    def test_allowed_origin_is_preserved_for_provider_and_validation_errors(self):
        server = relay.ThreadingHTTPServer(("127.0.0.1", 0), relay.Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        conn = http.client.HTTPConnection("127.0.0.1", server.server_port, timeout=5)
        self.addCleanup(conn.close)
        headers = {"Content-Type": "application/json", "Origin": "http://localhost:3000"}
        conn.request("POST", "/explain", json.dumps({"status": "INVALID", "amount_tnd": 1}), headers)
        response = conn.getresponse()
        self.assertEqual(response.status, 400)
        self.assertEqual(response.getheader("Access-Control-Allow-Origin"), headers["Origin"])
        self.assertEqual(json.load(response)["code"], "invalid_request")
        failure = relay.urllib.error.URLError(PermissionError("blocked"))
        with patch.object(relay, "generate", side_effect=failure):
            conn.request("POST", "/explain", json.dumps({"status": "SUBMITTED", "amount_tnd": 1}), headers)
            response = conn.getresponse()
            self.assertEqual(response.status, 502)
            self.assertEqual(response.getheader("Access-Control-Allow-Origin"), headers["Origin"])
            self.assertEqual(json.load(response)["code"], "provider_unreachable")


if __name__ == "__main__":
    unittest.main()
