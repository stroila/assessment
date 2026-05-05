 IMAGE_NAME := assessment-app
 DB_USER := assessment
 DB_NAME := assessment
 DB_PASS := "CZ6dwsGRIHKs1KcZlX8MTy"
 ROOT_PASS := "CZ6dwsGRIHKs1KcZlX8MTy"
 PHP_IMAGE_NAME := registry.redhat.io/rhel9/php-82:1-1777884059
 DB_IMAGE_NAME := registry.redhat.io/rhel9/mysql-84:1-1777466422
 S2I_DIR := s2i
  
  .PHONY: all setup build scan run clean
  
  all: setup build
  
  setup:
	mkdir -p $(S2I_DIR)/app-src
	podman pull $(PHP_IMAGE_NAME)
	podman pull $(DB_IMAGE_NAME)
	cd $(S2I_DIR) && git clone https://github.com/LimeSurvey/LimeSurvey.git app-src || true
	cp images/logo-w.png $(S2I_DIR)/app-src/assets/images/logo-white.png
	cp images/logo-w.png $(S2I_DIR)/app-src/themes/admin/Sea_Green/images/logo-white.png
	cp -r plugins/AuthOAuth2 $(S2I_DIR)/app-src/plugins
	cp -r plugins/GraphMailer $(S2I_DIR)/app-src/application/core/plugins
	cp patch/PHPMailer.php $(S2I_DIR)/app-src/vendor/phpmailer/phpmailer/src/PHPMailer.php
	cp Dockerfile $(S2I_DIR)/Dockerfile
  
  build: setup
	cd $(S2I_DIR) && podman build --squash -v /var/tmp:/var/tmp -t $(IMAGE_NAME) .
  
  scan:
	podman run --rm -v /run/podman/podman.sock:/var/run/docker.sock aquasec/trivy --insecure image --severity HIGH,CRITICAL localhost/$(IMAGE_NAME):latest
	podman run --rm -v /run/podman/podman.sock:/var/run/docker.sock aquasec/trivy --insecure image --severity HIGH,CRITICAL $(DB_IMAGE_NAME)
  
  run:
	podman run -d --name assessment-db -e MYSQL_USER=$(DB_USER) -e MYSQL_PASSWORD=$(DB_PASS) -e MYSQL_DATABASE=$(DB_NAME) -e MYSQL_ROOT_PASSWORD=$(ROOT_PASS) -p 3309:3306 $(DB_IMAGE_NAME)
	podman run -d --name assessment-app -v /var/tmp:/var/tmp -p 8443:8443 $(IMAGE_NAME)
  
  clean:
	podman rm -f assessment-app || true
	podman rm -f assessment-db || true
	podman rmi $(IMAGE_NAME) || true
	podman rmi $(DB_IMAGE_NAME) || true
	rm -rf $(S2I_DIR)

