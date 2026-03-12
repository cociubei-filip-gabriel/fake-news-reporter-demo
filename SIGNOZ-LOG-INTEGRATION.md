# SigNoz Log Integration for Java Maven Applications

This guide explains how to collect and visualize application logs in [SigNoz](https://signoz.io/) starting from a Java Maven (Spring Boot) application.

---

## Overview

SigNoz uses **OpenTelemetry** (OTel) as its data collection standard. For logs, the recommended approach is:

1. Your app writes structured logs via SLF4J/Logback.
2. The **OpenTelemetry Java Agent** (attached at JVM startup) automatically captures logs and exports them to the **OTel Collector**.
3. The OTel Collector forwards logs to **SigNoz**, where you query and visualize them.

```
Application (Logback/SLF4J)
       |
  OTel Java Agent (auto-instrumentation)
       |
  OTel Collector
       |
    SigNoz UI
```

---

## Step 1 — Deploy SigNoz

### Option A: Docker Compose (self-hosted)

```bash
git clone -b main https://github.com/SigNoz/signoz.git && cd signoz/deploy
docker compose -f docker/clickhouse-setup/docker-compose.yaml up -d
```

SigNoz UI will be available at `http://localhost:3301`.

### Option B: SigNoz Cloud

Sign up at [signoz.io](https://signoz.io/) and note your **ingestion endpoint** and **access token**.

---

## Step 2 — Configure Logging in Your Application

Ensure your application uses **SLF4J** with **Logback** (Spring Boot default). No extra Maven dependencies are needed for log collection since the OTel Java Agent handles it.

Verify your code uses standard SLF4J logging:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class MyService {
    private static final Logger log = LoggerFactory.getLogger(MyService.class);

    public void doWork() {
        log.info("Processing started");
        log.error("Something failed", exception);
    }
}
```

---

## Step 3 — Download the OpenTelemetry Java Agent

Download the latest OTel Java agent JAR:

```bash
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
```

Place it in a known location (e.g., project root or a `monitoring/` directory).

---

## Step 4 — Run the Application with the OTel Agent

Attach the agent to your JVM at startup. The agent auto-instruments Logback and exports logs via OTLP.

### Self-hosted SigNoz

```bash
java -javaagent:./opentelemetry-javaagent.jar \
  -Dotel.service.name=your-app-name \
  -Dotel.logs.exporter=otlp \
  -Dotel.exporter.otlp.endpoint=http://localhost:4317 \
  -Dotel.exporter.otlp.protocol=grpc \
  -jar target/d4c-portal-0.0.1-SNAPSHOT.jar
```

### SigNoz Cloud

```bash
java -javaagent:./opentelemetry-javaagent.jar \
  -Dotel.service.name=your-app-name \
  -Dotel.logs.exporter=otlp \
  -Dotel.exporter.otlp.endpoint=https://ingest.<region>.signoz.cloud:443 \
  -Dotel.exporter.otlp.headers=signoz-ingestion-key=<YOUR_INGESTION_KEY> \
  -Dotel.exporter.otlp.protocol=grpc \
  -jar target/d4c-portal-0.0.1-SNAPSHOT.jar
```

### Using Maven (development)

```bash
MAVEN_OPTS="-javaagent:./opentelemetry-javaagent.jar \
  -Dotel.service.name=d4c-portal \
  -Dotel.logs.exporter=otlp \
  -Dotel.exporter.otlp.endpoint=http://localhost:4317" \
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

---

## Step 5 — Verify Logs in SigNoz

1. Open the SigNoz UI (`http://localhost:3301` for self-hosted).
2. Navigate to **Logs** in the left sidebar.
4. You should see log entries with severity, message, timestamp, and trace context (if tracing is also enabled).

---

## Step 6 — (Optional) Create Dashboards and Alerts

In the SigNoz UI:

- **Dashboards**: Create panels that query logs by severity, service, or custom attributes.
- **Alerts**: Set up alerts for error spikes, e.g., "notify when ERROR log count > 10 in 5 minutes".

---

## Quick Reference

| Component | Purpose |
|---|---|
| SLF4J / Logback | Application logging framework |
| OTel Java Agent | Auto-captures logs and exports via OTLP |
| OTel Collector | Receives, processes, and forwards telemetry (bundled with SigNoz) |
| SigNoz | Storage, querying, and visualization |

## Key System Properties

| Property | Description |
|---|---|
| `otel.service.name` | Identifies your app in SigNoz |
| `otel.logs.exporter` | Set to `otlp` to enable log export |
| `otel.exporter.otlp.endpoint` | OTel Collector / SigNoz ingest URL |
| `otel.exporter.otlp.protocol` | `grpc` (default) or `http/protobuf` |
