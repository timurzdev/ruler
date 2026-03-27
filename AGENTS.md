# AGENTS.md - Project Context for AI Assistants

**⚠️ IMPORTANT: This file must be kept up-to-date by AI agents working on this project.**

When working on this project, always read this file first and update it when you learn new information about the project structure, architecture, or important decisions.

---

## Project Overview

**Project Name:** ruler  
**Type:** Kubernetes-native monitoring/alerting management application  
**Repository:** /home/tmogus/Coding/petprojects/ruler

### Purpose
Ruler is a Kubernetes-native application that provides a custom API server with SQLite backend and a controller that synchronizes alert rules with VictoriaMetrics VMRule CRDs through the VM Operator.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         KIND CLUSTER                             │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Namespace: monitoring                                   │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │  Victoria    │  │    Grafana   │  │  OTel        │   │    │
│  │  │  Metrics     │  │  (UI)        │  │  Collector   │   │    │
│  │  │  :8428       │  │  :3000       │  │              │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  │           ▲                                              │    │
│  │           └────────────────────────┐                     │    │
│  │  ┌──────────────┐                  │                     │    │
│  │  │ VM Operator  │◄─────────────────┘                     │    │
│  │  │ (CRDs)       │                                         │    │
│  │  └──────────────┘                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Namespace: ruler-system                                 │    │
│  │  ┌──────────────┐      ┌──────────────────┐             │    │
│  │  │ ruler-server │◄─────│ ruler-controller │             │    │
│  │  │ (gRPC API)   │      │ (VMRule sync)    │             │    │
│  │  │ + SQLite     │      │                  │             │    │
│  │  │ :8080        │      │                  │             │    │
│  │  └──────────────┘      └──────────────────┘             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Components

1. **ruler-server** (Go)
   - gRPC API server
   - SQLite database with migrations
   - Port: 8080 (configurable)
   - PVC for SQLite data persistence
   - Built-in database migrations on startup

2. **ruler-controller** (Go)
   - Watches API server for changes
   - Synchronizes with VMRule CRDs
   - Requires RBAC permissions for VM Operator CRDs
   - Cluster-scoped (single instance per cluster)

3. **VictoriaMetrics** (Infrastructure)
   - Time-series database for metrics
   - Receives data via prometheusremotewrite from OTel Collector
   - URL: `victoria-metrics-victoria-metrics-single-server.monitoring.svc.cluster.local:8428`

4. **Grafana** (Infrastructure)
   - Visualization and dashboards
   - Pre-configured VictoriaMetrics datasource
   - Access: http://grafana.local:8080
   - Login: admin / (auto-generated password)

5. **OpenTelemetry Collector** (Infrastructure)
   - Collects metrics from cluster
   - Sends to VictoriaMetrics via prometheusremotewrite
   - Uses contrib image for prometheusremotewrite exporter

6. **VM Operator** (Infrastructure)
   - Manages VictoriaMetrics CRDs (VMRule, VMAlert, etc.)
   - Required for controller to create VMRule resources

---

## Local Development Environment

### Prerequisites
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [Task](https://taskfile.dev/)

### Quick Start

```bash
# 1. Add hosts entry (run once)
echo "127.0.0.1 grafana.local" | sudo tee -a /etc/hosts

# 2. Deploy everything
task infra:all

# 3. Access Grafana
# URL: http://grafana.local:8080
# Login: admin
# Password: (shown after deployment)
```

### Task Commands

```bash
task --list                    # Show all available commands
task infra:all                 # Full deployment (cluster + infra)
task cluster:create            # Create kind cluster
task cluster:delete            # Delete kind cluster
task cluster:reset             # Recreate cluster
task infra:deploy              # Deploy infrastructure components
task infra:victoria-metrics    # Deploy VictoriaMetrics only
task infra:grafana             # Deploy Grafana only
task infra:otel-collector      # Deploy OTel Collector only
task infra:vm-operator         # Deploy VM Operator only
task demo:deploy               # Deploy OTel Demo (generates test metrics)
task demo:delete               # Remove OTel Demo
task app:load-images           # Load local Docker images into kind
task app:deploy                # Deploy ruler-server and ruler-controller
task app:delete                # Remove application
task app:logs                  # View application logs
task status                    # Show cluster status
```

---

## Project Structure

```
ruler/
├── Taskfile.yml                    # Task commands
├── sandbox/
│   ├── README.md                   # Detailed setup instructions
│   ├── kind-config.yaml            # Kind cluster configuration
│   ├── prepare-cluster.sh          # Dependency check script
│   ├── config/
│   │   ├── infra/                  # Infrastructure configs
│   │   │   ├── victoria-metrics/
│   │   │   │   └── values.yaml
│   │   │   ├── grafana/
│   │   │   │   └── values.yaml     # With VictoriaMetrics datasource
│   │   │   ├── otel-collector/
│   │   │   │   └── values.yaml     # prometheusremotewrite config
│   │   │   ├── vm-operator/
│   │   │   │   └── values.yaml
│   │   │   └── ingress-nginx/
│   │   │       └── values.yaml
│   │   └── app/                    # Application configs
│   │       ├── namespace.yaml      # ruler-system namespace
│   │       ├── ruler-server/
│   │       │   ├── deployment.yaml
│   │       │   ├── service.yaml
│   │       │   ├── pvc.yaml        # SQLite persistence
│   │       │   └── configmap.yaml  # gRPC port config
│   │       └── ruler-controller/
│   │           ├── deployment.yaml
│   │           ├── rbac.yaml       # ClusterRole for VMRule
│   │           └── configmap.yaml  # API server URL
│   └── scripts/
│       ├── load-images.sh          # kind load docker-image wrapper
│       └── setup-hosts.sh          # /etc/hosts setup helper
├── server/                         # ruler-server source code
└── controller/                     # ruler-controller source code
```

---

## Configuration Details

### VictoriaMetrics
- **Storage**: PVC (standard StorageClass)
- **Retention**: 30 days
- **Access**: `http://victoria-metrics-victoria-metrics-single-server.monitoring.svc.cluster.local:8428`
- **Data path**: `/storage`

### Grafana
- **Port**: 3000 (ClusterIP)
- **Ingress**: http://grafana.local:8080
- **Datasource**: VictoriaMetrics (pre-configured)
- **Persistence**: Disabled (ephemeral)

### OpenTelemetry Collector
- **Mode**: DaemonSet
- **Image**: otel/opentelemetry-collector-contrib (required for prometheusremotewrite)
- **Exporter**: prometheusremotewrite to VictoriaMetrics
- **Endpoint**: `http://victoria-metrics-victoria-metrics-single-server.monitoring.svc.cluster.local:8428/api/v1/write`

### ruler-server
- **gRPC Port**: 8080 (configurable via ConfigMap)
- **Database**: SQLite at `/data/ruler.db`
- **Persistence**: PVC `ruler-server-data` (1Gi)
- **Migrations**: Built into application (run on startup)

### ruler-controller
- **API Server URL**: `ruler-server.ruler-system.svc.cluster.local:8080`
- **RBAC**: ClusterRole with permissions for VMRule CRDs
- **Sync Interval**: 30s (configurable)

---

## Namespaces

| Namespace | Purpose | Components |
|-----------|---------|------------|
| `monitoring` | Infrastructure | VictoriaMetrics, Grafana, OTel Collector, VM Operator |
| `ruler-system` | Application | ruler-server, ruler-controller |
| `otel-demo` | Test data | OpenTelemetry Demo services |
| `ingress-nginx` | Ingress | NGINX Ingress Controller |

---

## Important Decisions

1. **Storage for VictoriaMetrics**: Using PVC instead of hostPath for simplicity
2. **OTel Collector Image**: Using `contrib` image to get prometheusremotewrite exporter
3. **Application Namespace**: Separate `ruler-system` namespace for application components
4. **Ingress**: NGINX with NodePort service (not LoadBalancer, for local dev)
5. **SQLite Migrations**: Built into application, not initContainer (simpler)
6. **Local Images**: Using `kind load docker-image` for local development

---

## Known Issues & Limitations

1. **OpenTelemetry Demo**: Resource-intensive, takes time to deploy
2. **Data Persistence**: VictoriaMetrics data persists only while cluster exists (PVC lifecycle tied to kind cluster)
3. **Grafana**: Ephemeral storage - dashboards need to be re-imported after restart
4. **Local Registry**: Currently using `kind load docker-image`, could switch to local registry for faster iteration

---

## Testing & Verification

### Check if metrics are flowing:
```bash
# Query VictoriaMetrics for available metrics
kubectl exec -n monitoring statefulset/victoria-metrics-victoria-metrics-single-server \
  -- wget -qO- 'http://127.0.0.1:8428/api/v1/label/__name__/values'
```

### Check VictoriaMetrics health:
```bash
kubectl exec -n monitoring statefulset/victoria-metrics-victoria-metrics-single-server \
  -- wget -qO- 'http://127.0.0.1:8428/health'
```

### Check Grafana datasource:
```bash
# Access http://grafana.local:8080
# Check Configuration → Data sources → VictoriaMetrics
```

### Check OTel Collector logs:
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
```

---

## Development Workflow

### Building and deploying application:

```bash
# 1. Build Docker images
docker build -t ruler-server:latest ./server
docker build -t ruler-controller:latest ./controller

# 2. Load into kind
task app:load-images

# 3. Deploy
task app:deploy

# 4. Check logs
task app:logs
```

### Iterating on infrastructure:

```bash
# Quick reset (keeps cluster, redeploys everything)
task infra:delete
task infra:deploy

# Full reset (recreates cluster)
task reset
```

---

## Future Improvements

- [ ] Add Tilt for hot-reload during development
- [ ] Add local Docker registry for faster image iteration
- [ ] Add Grafana dashboards as code (JSON in git)
- [ ] Add VictoriaLogs for centralized logging (if needed)
- [ ] Add tracing support (Jaeger in memory for local dev)
- [ ] Add integration tests for controller
- [ ] Add CI/CD pipeline for automated testing

---

## AI Agent Instructions

### When starting work on this project:

1. **Read this file first** - Always check AGENTS.md for current context
2. **Verify environment** - Run `task status` to see current cluster state
3. **Check running pods** - Ensure infrastructure is up before making changes

### When making changes:

1. **Update this file** - Document any new decisions, changes to architecture, or important findings
2. **Test thoroughly** - Run full deployment and verify metrics flow
3. **Update README.md** - If changing user-facing setup instructions

### When adding new components:

1. Add to appropriate namespace (monitoring for infra, ruler-system for app)
2. Update architecture diagram in this file
3. Add task commands to Taskfile.yml
4. Document in Configuration Details section
5. Update Project Structure

### When troubleshooting:

1. Check `task status` for pod health
2. Check component-specific logs
3. Verify service connectivity
4. Document solution in Known Issues section

---

## Last Updated

**Date:** 2026-03-27  
**Updated by:** AI Agent  
**Version:** 1.0

---

**Remember: Always keep this file updated with the latest project information!**
