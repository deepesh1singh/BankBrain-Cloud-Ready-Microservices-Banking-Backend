import sys
import os
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
from fastapi import FastAPI
from urllib.parse import urlparse, parse_qs

base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, base_dir)

import importlib.util

common_model_path = os.path.join(base_dir, 'common', 'model_client.py')
common_model_spec = importlib.util.spec_from_file_location("common.model_client", common_model_path)
common_model_module = importlib.util.module_from_spec(common_model_spec)
if 'common' not in sys.modules:
    import types
    sys.modules['common'] = types.ModuleType('common')
sys.modules['common.model_client'] = common_model_module
common_model_spec.loader.exec_module(common_model_module)

mcp_server_path = os.path.join(base_dir, 'mcp', 'bank_mcp_server', 'server.py')
mcp_spec = importlib.util.spec_from_file_location("mcp.bank_mcp_server.server", mcp_server_path)
mcp_module = importlib.util.module_from_spec(mcp_spec)
if 'mcp' not in sys.modules:
    import types
    sys.modules['mcp'] = types.ModuleType('mcp')
    sys.modules['mcp.bank_mcp_server'] = types.ModuleType('mcp.bank_mcp_server')
sys.modules['mcp.bank_mcp_server.server'] = mcp_module
mcp_spec.loader.exec_module(mcp_module)
mcp_app = mcp_module.app

support_agent_path = os.path.join(base_dir, 'agents', 'support-agent', 'app.py')
support_spec = importlib.util.spec_from_file_location("support_agent_app", support_agent_path)
support_module = importlib.util.module_from_spec(support_spec)
support_spec.loader.exec_module(support_module)
support_app = support_module.app

a2a_gateway_path = os.path.join(base_dir, 'agents', 'a2a-gateway', 'app.py')
a2a_spec = importlib.util.spec_from_file_location("a2a_gateway_app", a2a_gateway_path)
a2a_module = importlib.util.module_from_spec(a2a_spec)
a2a_spec.loader.exec_module(a2a_module)
a2a_app = a2a_module.app

mock_bank_app = FastAPI(title="Mock Bank API")

@mock_bank_app.get("/api/v1/accounts/{user_id}/transactions")
def get_transactions(user_id: str, days: int = 30):
    return [
        {"id": "tx1", "amount": 100.0, "date": "2024-01-01", "description": "Deposit"},
        {"id": "tx2", "amount": -50.0, "date": "2024-01-02", "description": "Withdrawal"},
        {"id": "tx3", "amount": 200.0, "date": "2024-01-03", "description": "Deposit"},
    ]

@mock_bank_app.get("/api/v1/accounts/{user_id}/balance")
def get_balance(user_id: str):
    return {"user_id": user_id, "balance": 1500.0, "currency": "USD"}

mock_bank_client = TestClient(mock_bank_app)
mcp_client = TestClient(mcp_app)
support_client = TestClient(support_app)
a2a_client = TestClient(a2a_app)

def mock_requests_get(url, *args, **kwargs):
    mock_response = MagicMock()
    parsed = urlparse(url)
    path = parsed.path
    query_params = parse_qs(parsed.query)
    params = {k: v[0] if len(v) == 1 else v for k, v in query_params.items()}
    
    response = mock_bank_client.get(path, params=params)
    mock_response.json.return_value = response.json()
    mock_response.status_code = response.status_code
    mock_response.ok = response.status_code == 200
    return mock_response

def mock_requests_post(url, *args, **kwargs):
    mock_response = MagicMock()
    if "mcp" in url.lower() or "mcp-bank-server" in url.lower():
        path = "/tool"
        json_data = kwargs.get("json", {})
        response = mcp_client.post(path, json=json_data)
        mock_response.json.return_value = response.json()
        mock_response.status_code = response.status_code
        mock_response.ok = response.status_code == 200
        return mock_response
    raise Exception(f"Unexpected URL: {url}")

def mock_generate_text(prompt: str, model_name: str = None, project: str = None, location: str = None) -> str:
    return "This is a mocked AI response."

def test_support_agent_chat_flow():
    original_mcp_get = mcp_module.requests.get
    original_support_post = support_module.requests.post
    original_common_generate_text = common_model_module.generate_text
    
    mcp_module.requests.get = mock_requests_get
    support_module.requests.post = mock_requests_post
    common_model_module.generate_text = mock_generate_text
    if hasattr(support_module, 'generate_text'):
        support_module.generate_text = mock_generate_text
    
    try:
        response = support_client.post(
            "/chat",
            json={"user_id": "user1", "message": "What are my recent transactions?"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "reply" in data
        assert "context" in data
        assert data["reply"] == "This is a mocked AI response."
        assert "result" in data["context"] or "error" in data["context"]
        
        print("Support Agent Response:")
        print(f"  Reply: {data['reply']}")
        print(f"  Context: {data['context']}")
        
        return data
    finally:
        mcp_module.requests.get = original_mcp_get
        support_module.requests.post = original_support_post
        common_model_module.generate_text = original_common_generate_text
        if hasattr(support_module, 'generate_text'):
            support_module.generate_text = original_common_generate_text

def test_a2a_gateway_agent_card():
    response = a2a_client.get("/agent-card")
    
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "capabilities" in data
    assert "endpoints" in data
    assert data["name"] == "a2a-gateway"
    
    print("A2A Gateway Agent Card:")
    print(f"  Name: {data['name']}")
    print(f"  Capabilities: {data['capabilities']}")
    print(f"  Endpoints: {data['endpoints']}")
    
    return data

if __name__ == "__main__":
    print("=" * 60)
    print("Running BankBrain Smoke Tests")
    print("=" * 60)
    
    print("\n1. Testing Support Agent Chat Flow (POST /chat)")
    print("-" * 60)
    support_result = test_support_agent_chat_flow()
    
    print("\n2. Testing A2A Gateway Agent Card (GET /agent-card)")
    print("-" * 60)
    a2a_result = test_a2a_gateway_agent_card()
    
    print("\n" + "=" * 60)
    print("All smoke tests passed!")
    print("=" * 60)
