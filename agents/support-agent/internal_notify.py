
from fastapi import FastAPI, Request
app = FastAPI()

@app.post("/internal_notify")
async def internal_notify(payload: dict):
    print("A2A notify received:", payload)
    return {"ok": True}
