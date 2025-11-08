
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Dict, Any
import requests, os

app = FastAPI(title="Bank MCP Server")

BANK_BASE = os.getenv("BANK_BASE_URL", "http://frontend.bank.svc.cluster.local")

class ToolCall(BaseModel):
    name: str
    args: Dict[str, Any] = {}

@app.get("/healthz")
def healthz():
    return {"ok": True}

@app.get("/tools")
def list_tools():
    return [
        {"name": "get_balance", "schema": {"user_id": "str"}},
        {"name": "list_transactions", "schema": {"user_id": "str", "since_days": "int"}},
        {"name": "initiate_payment", "schema": {"from_acct": "str", "to_acct": "str", "amount": "float", "memo": "str"}},
        {"name": "create_contact", "schema": {"user_id": "str", "name": "str", "acct": "str"}},
        {"name": "create_watch_rule", "schema": {"user_id": "str", "rule": "str"}},
    ]

@app.post("/tool")
def call_tool(req: ToolCall):
    name = req.name
    args = req.args or {}
    if name == "list_transactions":
        user_id = args.get("user_id", "user1")
        since = args.get("since_days", 30)
        try:
            r = requests.get(f"{BANK_BASE}/api/v1/accounts/{user_id}/transactions?days={since}", timeout=10)
            return {"name": name, "result": r.json()}
        except Exception as ex:
            return {"name": name, "error": str(ex)}
    if name == "get_balance":
        user_id = args.get("user_id", "user1")
        try:
            r = requests.get(f"{BANK_BASE}/api/v1/accounts/{user_id}/balance", timeout=10)
            return {"name": name, "result": r.json()}
        except Exception as ex:
            return {"name": name, "error": str(ex)}
    if name == "create_watch_rule":
        return {"name": name, "result": {"status": "ok", "rule": args.get("rule")}}
    return {"name": name, "error": "unknown_tool"}
