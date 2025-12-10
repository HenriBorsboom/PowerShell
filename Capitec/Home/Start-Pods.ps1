Function Start-HMBWoods {
    Param (
        [Switch] $Build
    )
    Switch ($Build) {
        $True {
            Write-Host "Building HMB-Woods Latest" -ForegroundColor Cyan
            podman build --no-cache -t hmb-woods:latest .
            Write-Host "Complete" -ForegroundColor Green
        }
    }
    Write-Host "Starting HMB Woods" -ForegroundColor Cyan
    podman run -d -it `
        -p 5000:5000 `
        --name hmbwoods `
        --env-file .env `
        -v downloads:/app/downloads `
        hmb-woods:latest
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "Enabling port proxy for port 5000" -ForegroundColor Cyan
    netsh interface portproxy add v4tov4 listenport=5000 listenaddress=0.0.0.0 connectaddress=127.0.0.1 connectport=5000
    Write-Host "Complete" -ForegroundColor Green
}
Function Start-N8n {
    Param (
        [Switch] $Build
    )
    Switch ($Build) {
        $True {
            Write-Host "Creating N8n Data volume" -ForegroundColor Cyan
            podman volume create n8n_data
            Write-Host "Complete" -ForegroundColor Green
            Write-Host "Creating N8n Certs volume" -ForegroundColor Cyan
            podman volume create n8n_certs
            Write-Host "Complete" -ForegroundColor Green
            Write-Host "Copying certificates to Certs volume" -ForegroundColor Cyan
            podman run --rm -v n8n_certs:/certs -v ${PWD}:/tmp alpine sh -c "cp /tmp/n8n-selfsigned.* /certs/ && chmod 644 /certs/n8n-selfsigned.*"
            Write-Host "Complete" -ForegroundColor Green
            Write-Host "Building N8n Latest" -ForegroundColor Cyan
            podman build --no-cache -t hmb-woods:latest .
            Write-Host "Complete" -ForegroundColor Green
        }
    }
    Write-Host "Starting N8n" -ForegroundColor Cyan
    podman run -d --restart unless-stopped -it `
      -p 5678:5678 `
      --name n8n `
      -v n8n_data:/home/node/.n8n `
      -v n8n_certs:/certs `
      -e N8N_PROTOCOL=https `
      -e N8N_SSL_KEY=/certs/n8n-selfsigned.key `
      -e N8N_SSL_CERT=/certs/n8n-selfsigned.crt `
      docker.n8n.io/n8nio/n8n
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "Enabling port proxy for port 5678" -ForegroundColor Cyan
    netsh interface portproxy add v4tov4 listenport=5678 listenaddress=0.0.0.0 connectaddress=127.0.0.1 connectport=5678
    Write-Host "Complete" -ForegroundColor Green
}
Function Start-Website {
    Write-Host "Starting Website" -ForegroundColor Cyan
    podman run -d --restart unless-stopped -it `
      -p 8090:80 `
      --name website `
      nginx
    Write-Host "Complete" -ForegroundColor Green
    Write-Host "Enabling port proxy for port 8090" -ForegroundColor Cyan
    netsh interface portproxy add v4tov4 listenport=8090 listenaddress=0.0.0.0 connectaddress=127.0.0.1 connectport=8090
    Write-Host "Complete" -ForegroundColor Green
}

Clear-Host
Set-Location 'E:\VMs\Python\HMB Woods'
Write-Host "Starting Podman Machine" -ForegroundColor Cyan
podman machine start
Write-Host "Complete" -ForegroundColor Green
Start-HMBWoods
Start-N8n
Start-Website
