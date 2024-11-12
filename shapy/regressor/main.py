import os
import uuid
import subprocess
from urllib.request import urlretrieve

import runpod
import numpy as np

if not os.path.exists(os.getenv("TEMP_DIR")):
    os.makedirs(os.getenv("TEMP_DIR"))

def dl_image(url):
    # define temporary folder
    key = str(uuid.uuid4())
    path = os.path.join(os.getenv("TEMP_DIR"), key)

    # create dirs
    os.mkdir(path)
    os.mkdir(os.path.join(path, "images"))
    os.mkdir(os.path.join(path, "openpose"))
    os.mkdir(os.path.join(path, "shapy"))
    
    filename = os.path.join(path, "images", "img_00.jpg")
    urlretrieve(url, filename=filename)
    return path

def run_script(path):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(script_dir, "process_images.sh")

    result = subprocess.run(
        [script_path, path, os.getenv("SHAPY_DIR"), os.getenv("OPENPOSE_DIR")],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print("Error:", result.stderr)
        raise RuntimeError("An error occurred during script processing")
    
def handler(job):

    job_input = job["input"]
    image_url = job_input.get("image_url")

    if not image_url:
        return

    path = dl_image(image_url)
    run_script(path)
    data = np.load(os.path.join(path, "shapy", "img_00.npz"), allow_pickle=True)
    results = {k: v[0].item() for k, v in data["measurements"].tolist().items()}

    return results

if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
