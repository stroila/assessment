Assessment Application – Podman Deployment
==========================================

This project builds and deploys an Assessment (LimeSurvey-based) application
using Podman. The stack uses S2I, macvlan networking, and Red Hat container
images for PHP, MySQL, and NGINX.

------------------------------------------------------------
Architecture Overview
------------------------------------------------------------

The deployment consists of three containers:

- Application container (PHP / LimeSurvey)
- Database container (MySQL 8.4)
- Load balancer / reverse proxy (NGINX)

Each component runs on its own macvlan network with static IP addresses.

Host
 ├─ macvlan-shim
 │   ├─ 192.168.1.6 (app_net access)
 │   └─ 192.168.2.6 (db_net access)
 │
 ├─ app (192.168.1.5) ── app_net
 ├─ db  (192.168.2.5) ── db_net
 └─ lb  (443 → 8443)

------------------------------------------------------------
Configuration Variables
------------------------------------------------------------

IMAGE_NAME        := app
DB_USER           := assessment
DB_NAME           := assessment
DB_PASS           := "change-me"
ROOT_PASS         := "change-me"
DB_VOLUME         := "db-data"
IFC               := "eth0"

PHP_IMAGE_NAME    := registry.redhat.io/rhel9/php-82:1-1777884059
DB_IMAGE_NAME     := registry.redhat.io/rhel9/mysql-84:1-1777466422
PROXY_IMAGE_NAME  := registry.redhat.io/rhel9/nginx-126:1-1777916570

S2I_DIR           := s2i

IMPORTANT:
Change database passwords before using this in production.

------------------------------------------------------------
Prerequisites
------------------------------------------------------------

- Podman (rootful mode required)
- Git
- A network interface supporting macvlan (default: eth0)
- Internet access to pull container images

------------------------------------------------------------
Make Targets
------------------------------------------------------------

make all
  Runs setup and build stages.

make setup
  - Pulls PHP, MySQL, and NGINX images
  - Clones LimeSurvey into the S2I directory
  - Applies branding (logos)
  - Installs custom plugins
  - Patches PHPMailer
  - Copies Dockerfile for S2I builds

make build
  - Creates macvlan networks:
      app_net (192.168.1.0/29)
      db_net  (192.168.2.0/29)
  - Creates macvlan shim interface for host connectivity
  - Creates database volume if missing
  - Builds application and load balancer images

make scan
  - Scans images using Trivy
  - Reports HIGH and CRITICAL vulnerabilities only

make run
  - Starts database container:
      Network: db_net
      IP:      192.168.2.5
  - Starts application container:
      Network: app_net
      IP:      192.168.1.5
  - Starts NGINX load balancer:
      Exposes HTTPS on port 443

make clean
  - Removes containers
  - Removes built images
  - Deletes S2I working directory

------------------------------------------------------------
Networking Notes
------------------------------------------------------------

- macvlan is required to support static IP addressing
- Podman must run as root
- macvlan-shim enables host-to-container communication
- /29 subnets are used for minimal network exposure

------------------------------------------------------------
Volumes and Persistence
------------------------------------------------------------

- MySQL data is stored in the Podman volume:
    db-data

- NGINX configuration and logs:
    /opt/nginx
    /opt/nginx/logs

------------------------------------------------------------
Security Notes
------------------------------------------------------------

- Image vulnerability scanning is included via Trivy
- Credentials are stored in plaintext variables
- TLS termination is handled by NGINX

------------------------------------------------------------
Troubleshooting
------------------------------------------------------------

Static IP issues:
  - Ensure Podman is running rootful
  - Verify macvlan support on the selected interface

No host connectivity:
  - Check macvlan-shim routes with `ip route`

Database connection failures:
  - Validate credentials
  - Confirm correct network attachment

------------------------------------------------------------
License and Attribution
------------------------------------------------------------

- LimeSurvey © LimeSurvey GmbH
- Container images provided by Red Hat
- Custom plugins and patches are project-specific

