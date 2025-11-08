
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel
import os, requests
from common.model_client import generate_text

PROJECT = os.getenv("PROJECT_ID", "")
LOCATION = os.getenv("LOCATION", "us-central1")
MODEL = os.getenv("MODEL_NAME", "gemini-2.5-pro")
MCP_URL = os.getenv("MCP_URL", "http://mcp-bank-server.bankbrain.svc.cluster.local")

app = FastAPI(title="Support Agent")

class ChatMsg(BaseModel):
    user_id: str
    message: str

@app.get("/healthz")
def healthz():
    return {"ok": True}

@app.get("/", response_class=HTMLResponse)
def ui():
    return '''<html><body>
      <h3>BankBrain Support Chat</h3>
      <form id='f' action='/chat' method='post'>
        User ID: <input name='user_id' value='user1'/><br/>
        Message: <input name='message' style='width:400px'/><br/>
        <button type='submit'>Send</button>
      </form>
      <pre id='out'></pre>
      <script>
      const form = document.getElementById('f');
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData(form);
        const body = { user_id: formData.get('user_id'), message: formData.get('message') };
        const res = await fetch('/chat', { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(body) });
        const j = await res.json();
        document.getElementById('out').innerText = JSON.stringify(j, null, 2);
      });
      </script>
    </body></html>'''

@app.post("/chat")
def chat(msg: ChatMsg):
    try:
        tx = requests.post(f"{MCP_URL}/tool", json={"name": "list_transactions", "args": {"user_id": msg.user_id, "since_days": 30}}, timeout=10).json()
    except Exception as ex:
        tx = {"error": str(ex)}
    prompt = f"You are a banking copilot. Given the last 30 days transactions: {tx}.\nAnswer the user question: {msg.message}\nIf user requests an action, ALWAYS ask for explicit confirmation and do NOT execute without consent."
    reply = generate_text(prompt, model_name=MODEL, project=PROJECT, location=LOCATION)
    return JSONResponse({"reply": reply, "context": tx})
