UNAME := $(shell uname -s)
NAMESPACE := $(shell grep 'namespace:' $(HELM_CHART)/values.yaml | sed 's/^.*: //')
#NAMESPACE := $(shell grep 'namespace:' $(HELM_CHART)/values-arm-m1.yaml | sed 's/^.*: //')

.DEFAULT_GOAL:=help

##@ install			: Install new helm chart (e.g. make install HELM_CHART=<NAME>)
install:
ifeq ($(UNAME),Darwin)
	eval $(minikube -p minikube docker-env)
	docker build . -t dadjokes/arm-m1-dadjokes -f ARM_M1_CPU/Dockerfile
	helm install $(HELM_CHART) $(HELM_CHART) --values $(HELM_CHART)/values-arm-m1.yaml --namespace $(NAMESPACE) --create-namespace
else
	helm install $(HELM_CHART) $(HELM_CHART) --values $(HELM_CHART)/values.yaml --namespace $(NAMESPACE) --create-namespace
endif

##@ upgrade			: Upgrade helm chart with new values (e.g. make upgrade HELM_CHART=<NAME>)
upgrade:
ifeq ($(UNAME),Darwin)
	helm upgrade $(HELM_CHART) $(HELM_CHART) --values $(HELM_CHART)/values-arm-m1.yaml -n $(NAMESPACE)
else
	helm upgrade $(HELM_CHART) $(HELM_CHART) --values $(HELM_CHART)/values.yaml -n $(NAMESPACE)
endif

##@ dependencies		: Install and enable ingress and metrics-server minikube addons
dependencies:
	minikube addons enable ingress
	minikube addons enable metrics-server

##@ uninstall		: Uninstall the helm chart and delete the namespace (e.g. make uninstall HELM_CHART=<NAME>)
uninstall:
	helm uninstall $(HELM_CHART) -n $(NAMESPACE)
	kubectl delete namespace $(NAMESPACE)

##@ test			: Export the URL in minikube
test:
	minikube service helm-dadjokes --url -n $(NAMESPACE)

##@ metrics-server		: Install and enable the metrics-server minikube addon
metrics-server:
	minikube addons enable metrics-server

##@ ingress			: Install and enable the ingress minikube addon
ingress:
	minikube addons enable ingress

help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	