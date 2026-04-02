import runpod
import base64
import subprocess
import uuid
import os
import sys

sys.path.insert(0, "/workspace/Wan2.2")


def handler(event):
    input_data = event["input"]
    prompt = input_data.get("prompt", "")
    image_b64 = input_data.get("image_base64") or input_data.get("image")
    width = input_data.get("width", 832)
    height = input_data.get("height", 480)
    steps = input_data.get("steps", 25)
    seed = input_data.get("seed", 42)
    cfg = input_data.get("cfg", 5.0)
    length = input_data.get("length", 81)

    if not image_b64:
        return {"error": "Missing required 'image_base64' field (base64-encoded)"}
    if not prompt:
        return {"error": "Missing required 'prompt' field"}

    # Snap to nearest valid WAN 2.2 resolution
    VALID_SIZES = [
        (720, 1280), (1280, 720),
        (480, 832), (832, 480),
        (704, 1280), (1280, 704),
        (1024, 704), (704, 1024),
    ]
    best = min(VALID_SIZES, key=lambda s: abs(s[0] - width) + abs(s[1] - height))
    size = f"{best[0]}*{best[1]}"
    job_id = str(uuid.uuid4())[:8]
    image_path = f"/tmp/{job_id}.jpg"
    output_path = f"/tmp/{job_id}.mp4"

    try:
        # Decode input image
        with open(image_path, "wb") as f:
            f.write(base64.b64decode(image_b64))

        # Run generation — no offload_model for speed, convert_model_dtype to save VRAM
        cmd = [
            "python", "-u", "generate.py",
            "--task", "i2v-A14B",
            "--size", size,
            "--ckpt_dir", "/workspace/Wan2.2-I2V-A14B",
            "--convert_model_dtype",
            "--sample_steps", str(steps),
            "--image", image_path,
            "--prompt", prompt,
            "--save_file", output_path,
            "--frame_num", str(length),
            "--sample_guide_scale", str(cfg),
            "--base_seed", str(seed),
        ]

        result = subprocess.run(
            cmd,
            cwd="/workspace/Wan2.2",
            capture_output=True,
            text=True,
            timeout=1200,
        )

        if result.returncode != 0:
            return {
                "error": f"Generation failed (exit code {result.returncode})",
                "stderr": result.stderr[-2000:] if result.stderr else "",
            }

        if not os.path.exists(output_path):
            return {"error": "Generation completed but no output file was created"}

        # Read and return video
        with open(output_path, "rb") as f:
            video_b64 = base64.b64encode(f.read()).decode()

        return {"video": video_b64, "job_id": job_id}

    finally:
        # Clean up temp files
        for path in [image_path, output_path]:
            if os.path.exists(path):
                os.remove(path)


runpod.serverless.start({"handler": handler})
