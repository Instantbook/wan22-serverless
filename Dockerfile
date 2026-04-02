FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

RUN apt-get update && apt-get install -y git git-lfs ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Clone Wan2.2 code and install requirements
RUN cd /workspace && git clone https://github.com/Wan-Video/Wan2.2.git && \
    cd Wan2.2 && pip install -r requirements.txt

# Install additional deps
RUN pip install decord runpod "huggingface_hub[cli]"

# Download ALL model weights in chunks to keep layers manageable
# Config, small files, and VAE
RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "*.json" "*.txt" "*.md" "*.pth" "assets/*"

# T5 text encoder (already downloaded above via *.pth, but ensure completeness)
# Low noise model shards
RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00001*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00002*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00003*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00004*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00005*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "low_noise_model/diffusion_pytorch_model-00006*"

# High noise model shards
RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00001*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00002*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00003*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00004*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00005*"

RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "high_noise_model/diffusion_pytorch_model-00006*"

# Google tokenizer files
RUN huggingface-cli download Wan-AI/Wan2.2-I2V-A14B \
    --local-dir /workspace/Wan2.2-I2V-A14B \
    --include "google/**"

# Install optional deps needed for WAN 2.2 imports (skip SAM-2, not needed for I2V)
RUN pip install peft librosa openai-whisper onnxruntime decord sentencepiece \
    HyperPyYAML inflect omegaconf conformer loguru modelscope

# Copy handler
COPY handler.py /workspace/handler.py

# Health check endpoint is built into runpod serverless
CMD ["python", "-u", "/workspace/handler.py"]
