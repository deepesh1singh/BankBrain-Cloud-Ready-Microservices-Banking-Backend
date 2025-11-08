
REPO ?= gcr.io/$(PROJECT_ID)
TAG ?= v0.1.0

build-images:
	docker build -t $(REPO)/bankbrain-mcp-server:$(TAG) ./mcp/bank_mcp_server
	docker build -t $(REPO)/bankbrain-support-agent:$(TAG) ./agents/support-agent
	docker build -t $(REPO)/bankbrain-risk-agent:$(TAG) ./agents/risk-agent
	docker build -t $(REPO)/bankbrain-a2a-gateway:$(TAG) ./agents/a2a-gateway

push-images:
	docker push $(REPO)/bankbrain-mcp-server:$(TAG)
	docker push $(REPO)/bankbrain-support-agent:$(TAG)
	docker push $(REPO)/bankbrain-risk-agent:$(TAG)
	docker push $(REPO)/bankbrain-a2a-gateway:$(TAG)
