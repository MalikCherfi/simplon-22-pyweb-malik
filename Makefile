.PHONY: build
build: 
	@docker build -t simplon-22-pyweb-malik .
	@echo "Docker image built successfully: simplon-22-pyweb-malik"
	@docker volume create simplon-22-pyweb-malik-volume
	@echo "Docker volume created successfully: simplon-22-pyweb-malik-volume"

.PHONY: run
run:
	@docker run -dp 8000:8000 --name simplon-22-pyweb-malik --mount type=volume,src=simplon-22-pyweb-malik-volume,target=/data simplon-22-pyweb-malik
	@echo "Docker container started successfully: simplon-22-pyweb-malik"

.PHONY: stop
stop:
	@docker stop simplon-22-pyweb-malik
	@echo "Docker container stopped successfully: simplon-22-pyweb-malik"

.PHONY: start
start:
	@docker start simplon-22-pyweb-malik
	@echo "Docker container started successfully: simplon-22-pyweb-malik"

.PHONY: restart
restart:
	@docker restart simplon-22-pyweb-malik
	@echo "Docker container restarted successfully: simplon-22-pyweb-malik"

.PHONY: rm
rm:
	@docker rm -f simplon-22-pyweb-malik
	@echo "Docker container removed successfully: simplon-22-pyweb-malik"

.PHONY: clean
clean:
	@docker rmi simplon-22-pyweb-malik
	@echo "Docker image removed successfully: simplon-22-pyweb-malik"

.PHONY: kill
kill:
	@docker rm -f simplon-22-pyweb-malik
	@echo "Docker container killed successfully: simplon-22-pyweb-malik"
	@docker volume rm simplon-22-pyweb-malik-volume
	@echo "Docker volume removed successfully: simplon-22-pyweb-malik-volume"