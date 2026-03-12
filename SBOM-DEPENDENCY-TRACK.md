# SBOM & Dependency-Track Guide

## 1. Add the CycloneDX Maven Plugin

Add the following plugin to the `<build><plugins>` section of `pom.xml`:

```xml
<plugin>
    <groupId>org.cyclonedx</groupId>
    <artifactId>cyclonedx-maven-plugin</artifactId>
    <version>2.8.2</version>
    <configuration>
        <projectType>application</projectType>
        <schemaVersion>1.5</schemaVersion>
        <includeBomSerialNumber>true</includeBomSerialNumber>
        <includeCompileScope>true</includeCompileScope>
        <includeProvidedScope>true</includeProvidedScope>
        <includeRuntimeScope>true</includeRuntimeScope>
        <includeSystemScope>true</includeSystemScope>
        <includeTestScope>false</includeTestScope>
        <includeLicenseText>false</includeLicenseText>
        <outputFormat>all</outputFormat>
        <outputName>sbom</outputName>
    </configuration>
</plugin>
```

No additional Maven dependencies are required — the plugin resolves everything from the existing `pom.xml` dependency tree.

---

## 2. Generate the SBOM

Ensure the project compiles before generating:

```bash
mvn clean compile
mvn cyclonedx:makeAggregateBom
```

**Output files written to `target/`:**

| File | Format |
|------|--------|
| `target/sbom.json` | CycloneDX 1.5 JSON |
| `target/sbom.xml` | CycloneDX 1.5 XML |

The SBOM captures every resolved dependency (including transitive ones) across compile, runtime, provided, and system scopes. Test dependencies are excluded. Each entry includes component name, version, group, package URL (purl), and license information.

---

## 3. Start Dependency-Track

Create a `docker-compose.dtrack.yml` file:

```yaml
services:
  dtrack-apiserver:
    image: dependencytrack/apiserver:latest
    environment:
      ALPINE_DATABASE_MODE: internal
    volumes:
      - dtrack-data:/data
    ports:
      - "8081:8080"
    restart: unless-stopped

  dtrack-frontend:
    image: dependencytrack/frontend:latest
    environment:
      API_BASE_URL: http://localhost:8081
    ports:
      - "8082:8080"
    depends_on:
      - dtrack-apiserver
    restart: unless-stopped

volumes:
  dtrack-data:
```

Start the stack:

```bash
docker compose -f docker-compose.dtrack.yml up -d
```

Wait ~30 seconds for the API server to fully initialize, then open:

- **UI**: http://localhost:8082
- **Default credentials**: `admin` / `admin` — change immediately on first login

---

## 4. Upload the SBOM

### Option A — Web UI

1. Log in at http://localhost:8082
2. **Projects → Create Project** — set a name (e.g. `d4c-portal`) and version
3. Open the project → **Components → Upload BOM**
4. Select `target/sbom.json` and confirm

### Option B — REST API (CI/CD)

First, generate an API key: **Administration → Access Management → API Keys → Create**.

```bash
curl -X POST http://localhost:8081/api/v1/bom \
  -H "X-Api-Key: <YOUR_API_KEY>" \
  -F "projectName=d4c-portal" \
  -F "projectVersion=0.1.0" \
  -F "autoCreate=true" \
  -F "bom=@target/sbom.json"
```

---

## 5. Review Results

After upload, vulnerability analysis runs automatically in the background (typically under a minute):

- **Dashboard** — overall risk score and vulnerability counts by severity
- **Project → Components** — full inventory of all resolved dependencies
- **Project → Vulnerabilities** — CVEs mapped to specific components
- **Project → Policy Violations** — license compliance and custom policy checks

Use **Findings → Export** to download a vulnerability report as CSV or JSON.
