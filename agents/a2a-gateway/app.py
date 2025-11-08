
from fastapi import FastAPI
from pydantic import BaseModel
from typing import Dict, Any
import requests, os

app = FastAPI(title="A2A Gateway (minimal)")

class Msg(BaseModel):
    to: str
    capability: str
    payload: Dict[str, Any]

@app.get("/agent-card")
def agent_card():
    return {
        "name": "a2a-gateway",
        "capabilities": ["notify_user", "request_consent"],
        "endpoints": {"messages": "/messages"}
    }

@app.post("/messages")
def messages(msg: Msg):
    if msg.to == "support-agent":
        try:
            support_url = os.getenv("SUPPORT_URL", "http://support-agent.bankbrain.svc.cluster.local")
            # Attempt to deliver to support agent; support-agent should implement /internal_notify to receive these messages.
            requests.post(f"{support_url}/internal_notify", json=msg.payload, timeout=5)
            return {"ok": True, "routed_to": "support-agent"}
        except Exception as ex:
            return {"ok": False, "error": str(ex)}
    return {"ok": False, "error": "unknown_target"}
