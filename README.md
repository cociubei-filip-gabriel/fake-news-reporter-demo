# Fake News Reporter

[![CI](https://github.com/automatica-cluj/demo-project/actions/workflows/ci.yml/badge.svg)](https://github.com/automatica-cluj/demo-project/actions/workflows/ci.yml)
[![Build and Push](https://github.com/automatica-cluj/demo-project/actions/workflows/build-push.yml/badge.svg)](https://github.com/automatica-cluj/demo-project/actions/workflows/build-push.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/automatica-cluj/demo-project)](https://github.com/automatica-cluj/demo-project/releases)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io-blue)](https://github.com/automatica-cluj/demo-project/pkgs/container/demo-project)

A Spring Boot application for reporting and managing fake news sources. Users can report suspicious news sources, and administrators can verify and approve reports for public visibility!

**This project is educational, for demonstration purposes only!**

![infographics](infographics.png)

## Features

- **Public Features:**
  - View verified fake news reports
  - Report new fake news sources
  - Browse reports by category (Politics, Health, Science, Technology, Entertainment, Finance)

- **Admin Features:**
  - Secure login system
  - Review pending reports
  - Approve or reject reports
  - Delete inappropriate submissions

## Technology Stack

- **Backend:** Spring Boot 3.2.0
- **Frontend:** Thymeleaf with custom CSS
- **Security:** Spring Security with BCrypt password encoding
- **Database:** 
  - H2 (in-memory) for local development
  - PostgreSQL for production deployment
- **Build Tool:** Maven
- **Containerization:** Docker & Docker Compose

## Prerequisites

- Java 17 or higher
- Maven 3.6+
- Docker & Docker Compose (for production deployment)

## Running Locally (H2 Database)

1. Clone the repository:
```bash
git clone https://github.com/automatica-cluj/demo-project.git
cd demo-project
```

2. Build and run the application:
```bash
mvn spring-boot:run
```

3. Access the application:
   - Main application: http://localhost:8080
   - H2 Console: http://localhost:8080/h2-console
     - JDBC URL: `jdbc:h2:mem:fakenews`
     - Username: `sa`
     - Password: (leave empty)

4. Login credentials:
   - Username: `admin`
   - Password: `admin123`

## Running with Docker Compose (PostgreSQL)

1. Build and start the containers:
```bash
docker-compose up --build
```

2. Access the application:
   - Main application: http://localhost:8080

3. Stop the application:
```bash
docker-compose down
```

4. To remove all data (volumes):
```bash
docker-compose down -v
```

## Application Structure

```
src/main/java/com/automatica/fakenews/
├── config/              # Configuration classes (Security, Data initialization)
├── controller/          # Web controllers (Home, Admin)
├── dto/                 # Data Transfer Objects
├── model/               # JPA Entity classes
├── repository/          # Spring Data repositories
├── service/             # Business logic services
└── FakeNewsReporterApplication.java

src/main/resources/
├── static/css/          # CSS stylesheets
├── templates/           # Thymeleaf templates
│   ├── admin/          # Admin-specific templates
│   └── ...             # Public templates
├── application.yml      # Main configuration
├── application-local.yml    # H2 configuration
└── application-prod.yml     # PostgreSQL configuration
```

## API Endpoints

### Public Endpoints
- `GET /` - Home page with verified reports
- `GET /reports` - View all verified reports
- `GET /report` - Report submission form
- `POST /report` - Submit a new report
- `GET /login` - Admin login page

### Admin Endpoints (Authentication Required)
- `GET /admin/dashboard` - Admin dashboard
- `POST /admin/approve/{id}` - Approve a report
- `POST /admin/delete/{id}` - Delete a report

## Database Schema

### users
- `id` (BIGINT, Primary Key)
- `username` (VARCHAR, Unique)
- `password` (VARCHAR, BCrypt encoded)
- `role` (VARCHAR)
- `enabled` (BOOLEAN)

### fake_news_reports
- `id` (BIGINT, Primary Key)
- `news_source` (VARCHAR)
- `url` (VARCHAR)
- `category` (VARCHAR)
- `description` (TEXT)
- `reported_at` (TIMESTAMP)
- `approved` (BOOLEAN)
- `approved_at` (TIMESTAMP)
- `approved_by` (VARCHAR)

## Configuration Profiles

- **local** (default): Uses H2 in-memory database
- **prod**: Uses PostgreSQL database

Switch profiles using:
```bash
# Command line
mvn spring-boot:run -Dspring-boot.run.profiles=prod

# Environment variable
export SPRING_PROFILE=prod
```

## Building for Production

Build the JAR file:
```bash
mvn clean package
```

Run the JAR:
```bash
java -jar target/fake-news-reporter-1.0.0.jar
```

## SigNoz Log Integration

This project includes scripts for sending application logs to SigNoz with OpenTelemetry Java Agent.

1. Start SigNoz (self-hosted):
```powershell
.\scripts\start-signoz.ps1
```
SigNoz UI: `http://localhost:3301`

2. Download the OpenTelemetry Java agent:
```powershell
.\monitoring\download-otel-agent.ps1
```

3. Start the app with log export enabled:
```powershell
.\scripts\run-signoz.ps1
```

4. Generate quick test traffic (to create logs):
```powershell
.\scripts\verify-signoz.ps1
```

If you run with Docker Compose, use the SigNoz override file:
```powershell
docker compose -f docker-compose.yml -f docker-compose.signoz.yml up --build
```

Optional parameters:
```powershell
.\scripts\run-signoz.ps1 -Profile local -ServiceName fake-news-reporter -OtlpEndpoint http://localhost:4317 -OtlpProtocol grpc
```

For SigNoz Cloud, set ingestion key first:
```powershell
$env:SIGNOZ_INGESTION_KEY="your_ingestion_key"
.\scripts\run-signoz.ps1 -OtlpEndpoint https://ingest.<region>.signoz.cloud:443
```

Verify in SigNoz UI:
- Open `Logs`
- Filter by `service.name=fake-news-reporter`

## Environment Variables (Production)

- `SPRING_PROFILE` - Active profile (prod)
- `DB_HOST` - PostgreSQL host (default: localhost)
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_NAME` - Database name (default: fakenews)
- `DB_USER` - Database username (default: postgres)
- `DB_PASSWORD` - Database password (default: postgres)
- `HUGGINGFACE_API_TOKEN` - Hugging Face access token (required for AI fake/real detection)
- `HUGGINGFACE_API_URL` - Inference URL (optional override)

Local example (PowerShell):
```powershell
$env:HUGGINGFACE_API_TOKEN="hf_xxx_your_token_here"
mvn spring-boot:run
```

## SBOM + Dependency-Track (Varianta A)

1. Genereaza SBOM-ul CycloneDX:
```bash
mvn clean compile
mvn cyclonedx:makeAggregateBom
```
Fisierele rezultate sunt `target/sbom.json` si `target/sbom.xml`.

2. Porneste Dependency-Track:
```bash
docker compose -f docker-compose.dtrack.yml up -d
```
Interfata web: `http://localhost:8082` (user/parola initiale: `admin` / `admin`).

3. Upload SBOM (Varianta A - UI):
- Intra in UI -> `Projects` -> `Create Project`
- Intra in proiect -> `Components` -> `Upload BOM`
- Selecteaza `target/sbom.json`

4. Verificare vulnerabilitati:
- `Dashboard`: numar vulnerabilitati pe severitate
- `Project -> Vulnerabilities`: CVE-urile detectate
- `Project -> Components`: dependintele inventariate

Pentru ghid extins vezi `SBOM-DEPENDENCY-TRACK.md`.

## Security Notes

- The default admin password should be changed in production
- Passwords are stored using BCrypt hashing
- CSRF protection is enabled for all forms
- Spring Security protects admin endpoints

## License

This project is for demonstration purposes.

## Contributing

Feel free to submit issues and pull requests.
