# Deployment Guide

> Deploy RDD Framework in various environments.

## Prerequisites

- Task runner (go-task) >= 3.0
- Bash >= 4.0
- Git >= 2.0
- curl/wget for notifications

## Local Development

```bash
# Clone or initialize project
git clone <project-url>
cd project

# Initialize RDD
task rdd:init

# Verify setup
task doctor

# Run tests
task test
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

# Install Task
RUN curl -sL https://taskfile.dev/install.sh | sh

# Create app directory
WORKDIR /app

# Copy application
COPY . .

# Set permissions
RUN chmod +x .rdd/hooks/*.sh .rdd/scripts/*.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD task doctor --quick || exit 1

# Default command
CMD ["task", "start"]
```

### Build and Run

```bash
# Build image
docker build -t rdd-framework:latest .

# Run container
docker run -d \
    --name rdd-app \
    -e RDD_WECOM_WEBHOOK=https://... \
    -v $(pwd)/.rdd:/app/.rdd \
    rdd-framework:latest

# Check logs
docker logs -f rdd-app

# Run tasks
docker exec rdd-app task doctor
docker exec rdd-app task test
```

### Docker Compose

```yaml
version: '3.8'

services:
  rdd-app:
    build: .
    container_name: rdd-framework
    environment:
      - RDD_ENV=production
      - RDD_WECOM_WEBHOOK=${RDD_WECOM_WEBHOOK}
      - RDD_DEBUG=false
    volumes:
      - ./.rdd:/app/.rdd
      - ./docs:/app/docs
      - rdd-cache:/app/.rdd/cache
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "task", "doctor", "--quick"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  rdd-cache:
```

## Kubernetes Deployment

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rdd-config
data:
  RDD_ENV: "production"
  RDD_DEBUG: "false"
```

### Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rdd-secrets
type: Opaque
stringData:
  RDD_WECOM_WEBHOOK: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx"
```

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rdd-framework
  labels:
    app: rdd-framework
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rdd-framework
  template:
    metadata:
      labels:
        app: rdd-framework
    spec:
      containers:
        - name: rdd
          image: rdd-framework:latest
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: rdd-config
            - secretRef:
                name: rdd-secrets
          volumeMounts:
            - name: rdd-data
              mountPath: /app/.rdd/cache
            - name: rdd-logs
              mountPath: /app/.rdd/logs
          livenessProbe:
            exec:
              command:
                - task
                - doctor
                - --quick
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            exec:
              command:
                - task
                - doctor
                - --quick
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
      volumes:
        - name: rdd-data
          emptyDir: {}
        - name: rdd-logs
          emptyDir: {}
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: rdd-framework
spec:
  selector:
    app: rdd-framework
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `RDD_ENV` | No | `development` | Environment (development/staging/production) |
| `RDD_DEBUG` | No | `false` | Enable debug logging |
| `RDD_DIR` | No | `.rdd` | RDD directory path |
| `RDD_USER` | No | `$USER` | Current user for audit |
| `RDD_SESSION_ID` | No | Auto-generated | Session identifier |
| `RDD_WECOM_WEBHOOK` | For notifications | - | WeCom webhook URL |
| `RDD_DINGTALK_WEBHOOK` | For notifications | - | DingTalk webhook URL |
| `RDD_SLACK_WEBHOOK` | For notifications | - | Slack webhook URL |

## Production Checklist

### Before Deployment

- [ ] All tests passing (`task test`)
- [ ] Health check passing (`task doctor`)
- [ ] Configuration validated (`task config:validate`)
- [ ] Secrets properly set
- [ ] Backup created (`task rdd:backup`)

### During Deployment

- [ ] Blue/green or canary deployment
- [ ] Health checks passing
- [ ] Monitoring alerts configured
- [ ] Rollback plan ready

### After Deployment

- [ ] Verify notifications working
- [ ] Check audit logs
- [ ] Monitor resource usage
- [ ] Run smoke tests

## Scaling Considerations

### Single Instance (Recommended)

RDD Framework is designed for single-instance operation. Each project should have its own RDD instance.

### Multi-Project Setup

```yaml
# ~/.rdd/projects.yml
projects:
  - name: project-a
    path: /projects/project-a
    config: .rdd/config.yml
  - name: project-b
    path: /projects/project-b
    config: .rdd/config.yml
```

### Resource Limits

| Environment | CPU | Memory | Storage |
|-------------|-----|--------|---------|
| Development | 100m | 128Mi | 1Gi |
| Staging | 200m | 256Mi | 2Gi |
| Production | 500m | 512Mi | 5Gi |

## Monitoring

### Health Check Endpoint

```bash
# Kubernetes liveness
task doctor --quick

# Full health check
task doctor
```

### Metrics

```bash
# Export Prometheus metrics
task metrics:export

# View metrics
cat .rdd/cache/metrics.prom
```

### Log Aggregation

```yaml
# Filebeat configuration
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /app/.rdd/logs/*.log
    fields:
      type: rdd
    fields_under_root: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "rdd-logs-%{+yyyy.MM.dd}"
```

## Backup and Restore

### Automated Backups

```yaml
# CronJob for daily backups
apiVersion: batch/v1
kind: CronJob
metadata:
  name: rdd-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: rdd-framework:latest
              command:
                - task
                - rdd:backup
              volumeMounts:
                - name: backups
                  mountPath: /backups
          volumes:
            - name: backups
              persistentVolumeClaim:
                claimName: rdd-backups
          restartPolicy: OnFailure
```

### Manual Backup

```bash
# Create backup
task rdd:backup

# List backups
ls -la .rdd/backups/

# Restore from backup
task rdd:restore BACKUP_FILE=.rdd/backups/backup-2026-03-08.tar.gz
```
