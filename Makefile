 IMAGE_NAME := app
 DB_USER := assessment
 DB_NAME := assessment
 DB_PASS := "change-me"
 ROOT_PASS := "change-me"
 DB_VOLUME := "db-data"
 PHP_IMAGE_NAME := registry.redhat.io/rhel9/php-82:1-1777884059
 DB_IMAGE_NAME := registry.redhat.io/rhel9/mysql-84:1-1777466422
 PROXY_IMAGE_NAME := podman pull registry.redhat.io/rhel9/nginx-126:1-1777916570
 S2I_DIR := s2i
  
  .PHONY: all setup build scan run clean
  
  all: setup build
  
  setup:
	mkdir -p $(S2I_DIR)/app-src
	podman pull $(PHP_IMAGE_NAME)
	podman pull $(DB_IMAGE_NAME)
        podman pull $(PROXY_IMAGE_NAME)
	cd $(S2I_DIR) && git clone https://github.com/LimeSurvey/LimeSurvey.git app-src || true
	cp images/logo-w.png $(S2I_DIR)/app-src/assets/images/logo-white.png
	cp images/logo-w.png $(S2I_DIR)/app-src/themes/admin/Sea_Green/images/logo-white.png
	cp -r plugins/AuthOAuth2 $(S2I_DIR)/app-src/plugins
	cp -r plugins/GraphMailer $(S2I_DIR)/app-src/application/core/plugins
	cp patch/PHPMailer.php $(S2I_DIR)/app-src/vendor/phpmailer/phpmailer/src/PHPMailer.php
	cp Dockerfile $(S2I_DIR)/Dockerfile
  
  build: setup
	podman network create -d macvlan --subnet=192.168.0.0/30 --gateway=192.168.0.1 -o parent=eth0 lb_net
	podman network create -d macvlan --subnet=192.168.1.0/30 --gateway=192.168.1.1 -o parent=eth0 app_net
	podman network create -d macvlan --subnet=192.168.2.0/30 --gateway=192.168.2.1 -o parent=eth0 db_net
	podman volume exists $(DB_VOLUME) || podman volume create $(DB_VOLUME)
	cd $(S2I_DIR) && podman build --squash -v /var/tmp:/var/tmp -t $(IMAGE_NAME) .
	cd lb && podman build --squash -v /opt/nginx/:/opt/nginx -t nginx-app .
  
  scan:
	podman run --rm -v /run/podman/podman.sock:/var/run/docker.sock aquasec/trivy --insecure image --severity HIGH,CRITICAL localhost/$(IMAGE_NAME):latest
	podman run --rm -v /run/podman/podman.sock:/var/run/docker.sock aquasec/trivy --insecure image --severity HIGH,CRITICAL $(DB_IMAGE_NAME)
	podman run --rm -v /run/podman/podman.sock:/var/run/docker.sock aquasec/trivy --insecure image --severity HIGH,CRITICAL localhost/nginx-app:latest
  
  run:
	podman run -d --name db --restart=always --network db_net -e MYSQL_USER=$(DB_USER) -e MYSQL_PASSWORD=$(DB_PASS) -e MYSQL_DATABASE=$(DB_NAME) -e MYSQL_ROOT_PASSWORD=$(ROOT_PASS) -v $(DB_VOLUME):/var/lib/mysql/data -p 3308:3306 $(DB_IMAGE_NAME)
	podman run -d --name app --restart=always --network app_net -v /var/tmp:/var/tmp -p 8443:8443 $(IMAGE_NAME)
	podman run -d --name lb --restart=always --network lb_net -v /opt/nginx:/opt/nginx -v /opt/nginx/logs:/var/log/nginx -p 443:8443 localhost/nginx-app:latest
  
  clean:
	podman rm -f app || true
	podman rm -f db || true
	podman rm -f lb || true
	podman rmi $(IMAGE_NAME) || true
	podman rmi $(DB_IMAGE_NAME) || true
	podman rmi localhost/nginx-app:latest || true
	rm -rf $(S2I_DIR)

