# BankBrain Smoke Tests

End-to-end smoke tests for the BankBrain project that verify the complete integration flow without requiring network access, port binding, or external API calls.

## Overview

The smoke test validates the integration between:
- **Mock Bank API** - Simulated bank backend
- **MCP Server** - Bank MCP server (`mcp/bank_mcp_server/server.py`)
- **Support Agent** - Support agent service (`agents/support-agent/app.py`)
- **A2A Gateway** - Agent-to-agent gateway (`agents/a2a-gateway/app.py`)

## Features

- ✅ Uses FastAPI TestClient (no uvicorn, no ports)
- ✅ All network calls are mocked in-memory
- ✅ No external dependencies or API calls
- ✅ Tests complete request/response flows

## Test Flows

### 1. Support Agent Chat Flow
Tests the complete flow:
1. POST `/chat` to Support Agent
2. Support Agent calls MCP server `/tool` endpoint
3. MCP server calls Bank API for transactions
4. Support Agent generates AI response using mocked `generate_text()`

**Validates:**
- Support Agent receives chat request
- MCP integration works correctly
- Bank API mocking functions properly
- AI response generation is mocked

### 2. A2A Gateway Agent Card
Tests the agent card endpoint:
- GET `/agent-card` on A2A Gateway

**Validates:**
- Gateway returns correct agent metadata
- Response structure matches expected format

## Running the Tests

### Prerequisites

Install required dependencies:
```bash
pip install fastapi pydantic requests
```

### Execute Tests

```bash
cd tests
python smoke_test.py
```

Or from the project root:
```bash
python tests/smoke_test.py
```

## Expected Output

```
============================================================
Running BankBrain Smoke Tests
============================================================

1. Testing Support Agent Chat Flow (POST /chat)
------------------------------------------------------------
Support Agent Response:
  Reply: This is a mocked AI response.
  Context: {'name': 'list_transactions', 'result': [...]}

2. Testing A2A Gateway Agent Card (GET /agent-card)
------------------------------------------------------------
A2A Gateway Agent Card:
  Name: a2a-gateway
  Capabilities: ['notify_user', 'request_consent']
  Endpoints: {'messages': '/messages'}

============================================================
All smoke tests passed!
============================================================
```

## How It Works

The test uses Python's `unittest.mock` to patch network calls:

1. **Bank API Mocking**: `requests.get` in MCP server is patched to route calls to a mock FastAPI TestClient
2. **MCP Mocking**: `requests.post` in Support Agent is patched to route calls to the MCP TestClient
3. **AI Mocking**: `generate_text()` function is patched to return a fixed response

All services run in-memory using FastAPI TestClient, ensuring:
- No network traffic
- No port conflicts
- Fast execution
- Deterministic results

