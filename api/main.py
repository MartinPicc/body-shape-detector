import os
import uuid
import subprocess
from urllib.request import urlretrieve

import runpod

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
    process = subprocess.call(["./process_images.sh", path, os.getenv("SHAPY_DIR"), os.getenv("OPENPOSE_DIR")])
    assert process == 0, "An error occured during script processing"
    
def handler(job):

    job_input = job["input"]
    image_url = job_input["image_url"]

    path = dl_image(image_url)
    run_script(path)
    data = np.load(os.path.join(path, "shapy", "img_00.npz"), allow_pickle=True)

    return data["measurements"]

runpod.serverless.start({"handler": handler})
