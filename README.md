# Assessment
## Podman-Based Application Deployment

This project builds, scans, and deploys a **LimeSurvey PHP application** using **Podman**, **Source-to-Image (S2I)**, a **MySQL database**, and an **NGINX load balancer**. The setup is automated via a Makefile and uses isolated macvlan networks for each tier.

---

## Overview

### Components

- **Application**: LimeSurvey (PHP 8.2, RHEL 9)
- **Database**: MySQL 8.4 (RHEL 9)
- **Load Balancer**: NGINX (RHEL 9)
- **Container Runtime**: Podman
- **Build Method**: Source-to-Image (S2I)
- **Security Scanning**: Trivy

### Network Segmentation

- Load Balancer network
- Application network
- Database network

---

## Prerequisites

- Podman
- Git
- Access to `registry.redhat.io`
- Permission to create macvlan networks
- Network interface `eth0` available on the host

---

## Configuration

The following variables are defined in the Makefile:

```makefile
IMAGE_NAME := app

DB_USER    := assessment
DB_NAME    := assessment
DB_PASS    := "change-me"
ROOT_PASS  := "change-me"

DB_VOLUME  := db-data

PHP_IMAGE_NAME   := registry.redhat.io/rhel9/php-82:1-1777884059
DB_IMAGE_NAME    := registry.redhat.io/rhel9/mysql-84:1-1777466422
PROXY_IMAGE_NAME := registry.redhat.io/rhel9/nginx-126:1-1777916570

S2I_DIR := s2i
```

> **Important**: Change all credentials before production use.

---

## Directory Layout

```text
.
├── Dockerfile
├── Makefile
├── images/
│   └── logo-w.png
├── lb/
│   └── Dockerfile
├── patch/
│   └── PHPMailer.php
├── plugins/
│   ├── AuthOAuth2/
│   └── GraphMailer/
└── s2i/
    └── app-src/
```

---

## Makefile Targets

### all

Runs setup and build.

```bash
make all
```

---

### setup

- Creates the S2I directory structure
- Pulls required container images
- Clones LimeSurvey
- Applies branding, plugins, and patches

```bash
make setup
```

---

### build

- Creates macvlan networks:
  - `lb_net` – `192.168.0.0/30`
  - `app_net` – `192.168.1.0/30`
  - `db_net` – `192.168.2.0/30`
- Creates a persistent MySQL volume
- Builds the application and NGINX images

```bash
make build
```

---

### scan

Runs Trivy vulnerability scans showing **HIGH** and **CRITICAL** issues.

```bash
make scan
```

---

### run

Starts all containers:

| Service | Container | Host Port | Internal Port |
|--------|-----------|-----------|---------------|
| MySQL  | db        | 3308      | 3306          |
| App    | app       | 8443      | 8443          |
| NGINX  | lb        | 443       | 8443          |

```bash
make run
```

Access the application at:

```
https://<host-ip>:443
```

---

### clean

Stops and removes all containers, images, volumes, and build artifacts.

```bash
make clean
```

> **Warning**: This permanently deletes application data.

---

## Security Notes

- Replace default passwords immediately
- Run `make scan` regularly
- Limit macvlan exposure in production
- Secure host-mounted paths:
  - `/opt/nginx`
  - `/var/tmp`

---

## Licensing and Attribution

- **LimeSurvey**: GPLv2
- **Red Hat container images**: Red Hat subscription terms
- **Trivy**: Aqua Security
