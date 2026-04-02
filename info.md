# WAN 2.2 Serverless — Build & Deploy

## Step 1: Move Docker data to F: drive (one-time setup)

Docker Desktop stores images/cache on C: by default. Move it to F: so you have space for the ~50GB build.

### Option A: Docker Desktop GUI
1. Open Docker Desktop → Settings → Resources → Advanced
2. Change "Disk image location" to `F:\DockerData`
3. Click Apply & Restart

### Option B: WSL command line
```bash
wsl --shutdown
wsl --export docker-desktop-data F:\docker-desktop-data.tar
wsl --unregister docker-desktop-data
wsl --import docker-desktop-data F:\DockerData F:\docker-desktop-data.tar
del F:\docker-desktop-data.tar
```

## Step 2: Build the Docker image

```bash
cd /f/wan22-serverless
docker build -t dbazos/wan22-serverless:v1 .
```

This will take a while — it downloads ~28GB of model weights and packages.

## Step 3: Push to Docker Hub

```bash
docker login
docker push dbazos/wan22-serverless:v1
```

## Step 4: Create RunPod Serverless Endpoint

1. Go to RunPod → Serverless → New Endpoint
2. Container Image: `dbazos/wan22-serverless:v1`
3. GPU: 48GB VRAM minimum (A40, A6000, or L40S recommended)
4. Active Workers: 0 (scale to zero when idle)
5. Max Workers: 1+ (based on budget)
6. Idle Timeout: 5 seconds
7. Execution Timeout: 600 seconds

## Step 5: Test the endpoint

```python
import runpod
import base64

runpod.api_key = "YOUR_RUNPOD_API_KEY"
endpoint = runpod.Endpoint("YOUR_ENDPOINT_ID")

with open("test_image.jpg", "rb") as f:
    image_b64 = base64.b64encode(f.read()).decode()

result = endpoint.run_sync({
    "input": {
        "prompt": "A woman walking forward, natural movement",
        "image": image_b64,
        "size": "832*480",
        "steps": 25
    }
}, timeout=600)

if "video" in result:
    with open("output.mp4", "wb") as f:
        f.write(base64.b64decode(result["video"]))
    print("Saved output.mp4")
else:
    print(result)
```
