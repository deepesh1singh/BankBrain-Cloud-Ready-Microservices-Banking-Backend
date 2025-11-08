
import os, time, statistics, requests
from common.model_client import generate_text

MCP_URL = os.getenv("MCP_URL", "http://mcp-bank-server.bankbrain.svc.cluster.local")
A2A_URL = os.getenv("A2A_URL", "http://a2a-gateway.bankbrain.svc.cluster.local")
USER_ID = os.getenv("TEST_USER_ID", "user1")
POLL = int(os.getenv("POLL_INTERVAL", "30"))

def score_amounts(amounts):
    if len(amounts) < 5:
        return []
    mean = statistics.mean(amounts)
    stdev = statistics.pstdev(amounts) or 1.0
    return [(amt, (amt-mean)/stdev) for amt in amounts]

def notify_support(user_id, text):
    try:
        requests.post(f"{A2A_URL}/messages", json={
            "to": "support-agent",
            "capability": "notify_user",
            "payload": {"user_id": user_id, "text": text}
        }, timeout=5)
    except Exception as ex:
        print("notify failed:", ex)

if __name__ == '__main__':
    while True:
        try:
            r = requests.post(f"{MCP_URL}/tool", json={"name": "list_transactions", "args": {"user_id": USER_ID, "since_days": 1}}, timeout=10).json()
            txs = r.get("result", [])
            amounts = [abs(t.get("amount", 0)) for t in txs if isinstance(t, dict)]
            scored = score_amounts(amounts)
            suspicious = [a for a,z in scored if z > 2.5]
            if suspicious:
                rationale = generate_text(f"Explain in 2 sentences why {suspicious} looks anomalous. History: {amounts}")
                notify_support(USER_ID, rationale)
        except Exception as e:
            print("poll error:", e)
        time.sleep(POLL)
