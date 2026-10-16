# Command 1: Build without cache to ensure all dependencies are up-to-date
```bash
docker build --no-cache -t platform-api:trivy-check .
```

# Command 2: Run Trivy scan on the built image with specific options
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  platform-api:trivy-check
```

  ## Combined Command:
```bash
docker build --no-cache -t platform-api:trivy-check . && \
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  platform-api:trivy-check
```