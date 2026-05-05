# Assessment

Below is a concise, structured description of **what this deployment does and how it works**.

***

## Overview

This deployment builds and runs a **containerized LimeSurvey-based assessment application** using **Podman**. It consists of:

*   A **PHP 8.2 application container** (custom-built)
*   A **MySQL 8.4 database container** (Red Hat UBI image)
*   A **Source-to-Image (S2I)-style build process**
*   Optional **container image vulnerability scanning** with Trivy

The resulting system exposes:

*   The web application on **HTTPS port 8443**
*   The MySQL database on **port 3309 (host) → 3306 (container)**

***

## Components

### Application Container

*   **Image name:** `assessment-app`
*   **Base image:** `registry.redhat.io/rhel9/php-82`
*   **Application:** LimeSurvey (cloned from GitHub)
*   **Customizations:**
    *   Branding (logo replacement)
    *   OAuth2 authentication plugin
    *   GraphMailer plugin
    *   Patched PHPMailer implementation
*   **Build method:** Podman build with image squashing

### Database Container

*   **Image:** `registry.redhat.io/rhel9/mysql-84`
*   **Database name:** `assessment`
*   **Database user:** `assessment`
*   **Authentication:** Configured via environment variables at runtime
*   **Purpose:** Backend persistence for LimeSurvey

***

## Build and Deployment Workflow

### 1. Setup Phase (`make setup`)

*   Creates a working directory: `s2i/app-src`
*   Pulls required Red Hat PHP and MySQL base images
*   Clones the LimeSurvey repository
*   Injects:
    *   Custom logos
    *   Authentication and mailing plugins
    *   A patched PHPMailer file
    *   A Dockerfile for the application build

This stage effectively prepares a customized LimeSurvey source tree for containerization.

***

### 2. Build Phase (`make build`)

*   Builds the application image using Podman
*   Uses `--squash` to flatten layers and reduce image size
*   Mounts `/var/tmp` for temporary build artifacts
*   Produces a final image tagged as `assessment-app`

***

### 3. Security Scan (Optional) (`make scan`)

*   Runs **Trivy** vulnerability scans against:
    *   The custom application image
    *   The MySQL base image
*   Reports only **HIGH** and **CRITICAL** vulnerabilities
*   Uses Podman socket compatibility for scanning

Purpose: validate container security before deployment.

***

### 4. Runtime Deployment (`make run`)

#### Database

*   Starts MySQL container named `assessment-db`
*   Configures database name, user, and credentials via environment variables
*   Maps host port **3309 → 3306**

#### Application

*   Starts the application container named `assessment-app`
*   Exposes HTTPS on **port 8443**
*   Shares `/var/tmp` with the host (likely for uploads, caching, or S2I artifacts)

The application is expected to connect to the database container using the configured credentials.

***

### 5. Cleanup (`make clean`)

*   Stops and removes both containers
*   Deletes application and database images
*   Removes the entire `s2i` build directory

This returns the system to a clean state.

***

## Deployment Characteristics

*   **Container runtime:** Podman (daemonless, rootless-capable)
*   **Image sources:** Red Hat UBI (enterprise-supported)
*   **Security posture:**
    *   Explicit vulnerability scanning
    *   Reproducible builds
*   **Use case:** Internal or controlled assessment platform, not a managed cloud deployment

***

## Summary

This deployment creates a **self-contained LimeSurvey assessment platform** with:

*   Custom branding and authentication
*   Enterprise-grade Red Hat base images
*   A simple, Makefile-driven lifecycle (build, scan, run, clean)
*   Suitable for development, testing, or controlled production environments where Podman is preferred over Docker.

## Usage:
  - make — clone source, apply logos, build image
  - make scan — run Trivy vulnerability scan
  - make run — start the container
  - make clean — tear down container and image

