import os

os.environ['PYOPENGL_PLATFORM'] = 'egl'

import torch
import resource
from tqdm import tqdm
from loguru import logger
from omegaconf import OmegaConf, DictConfig
from threadpoolctl import threadpool_limits

from human_shape.config.defaults import conf as default_conf
from human_shape.models.build import build_model
from human_shape.data import build_all_data_loaders
from human_shape.data.structures.image_list import to_image_list


rlimit = resource.getrlimit(resource.RLIMIT_NOFILE)
resource.setrlimit(resource.RLIMIT_NOFILE, (rlimit[1], rlimit[1]))

#  torch.multiprocessing.set_start_method('fork')
torch.backends.cudnn.benchmark = True
torch.backends.cudnn.deterministic = False

@torch.no_grad()
def _run_model(exp_cfg: DictConfig) -> None:
    logger.remove()

    # init model
    model_dict = build_model(exp_cfg)
    model = model_dict["network"]
    model = model.to(device="cuda")
    model = model.eval()

    # init data
    part_key = exp_cfg.get('part_key', 'pose')
    dataloaders = build_all_data_loaders(
        exp_cfg, split="test", shuffle=False, enable_augment=False, return_full_imgs=True,
    )

    if isinstance(dataloaders[part_key], (list,)):
        assert len(dataloaders[part_key]) == 1
        body_dloader = dataloaders[part_key][0]
    else:
        body_dloader = dataloaders[part_key]
   
    # loop over each image
    results = {}
    for _, batch in enumerate(tqdm(body_dloader, dynamic_ncols=True, disable=True)):
        full_imgs_list, body_imgs, body_targets = batch
        
        if body_imgs is None:
            raise Exception("No body_imgs")
        
        full_imgs = to_image_list(full_imgs_list)
        body_imgs = body_imgs.to(device="cuda")
        body_targets = [target.to("cuda") for target in body_targets]
        if full_imgs is not None:
            full_imgs = full_imgs.to(device="cuda")

        torch.cuda.synchronize()
        model_output = model(
            body_imgs, body_targets, full_imgs=full_imgs, device="cuda"
        )
        torch.cuda.synchronize()
        
        stage_n_out = model_output['stage_02']
        fname = body_targets[0].get_field('fname')
        results[fname] = {k: v[0].item()
                          for k, v in stage_n_out["measurements"].items()}

    return results


def _init_cfg(path: str):
    cfg = default_conf.copy()
    
    exp_cfgs = ["../regressor/configs/b2a_expose_hrnet_demo.yaml"]
    
    for exp_cfg in exp_cfgs:
        if exp_cfg:
            cfg.merge_with(OmegaConf.load(exp_cfg))
    
    exp_opts = [
        "output_folder=../data/trained_models/shapy/SHAPY_A",
        "part_key=pose",
        f"datasets.pose.openpose.data_folder={path}",
        "datasets.pose.openpose.img_folder=images",
        "datasets.pose.openpose.keyp_folder=openpose",
        "datasets.batch_size=1",
        "datasets.pose_shape_ratio=1.0"
    ]
    
    if exp_opts:
        cfg.merge_with(OmegaConf.from_cli(exp_opts))
    
    cfg.is_training = False
    #  cfg.datasets[part_key].splits.test = cmd_args.datasets
    for part_key in ['pose', 'shape']:
        splits = cfg.datasets.get(part_key, {}).get('splits', {})
        if splits:
            splits['train'] = []
            splits['val'] = []
            splits['test'] = []
    part_key = cfg.get('part_key', 'pose')
    
    datasets = ["openpose"]
    cfg.datasets[part_key].splits["test"] = datasets

    return cfg


def run(path: str):
    cfg = _init_cfg(path)
    with threadpool_limits(limits=1):
        results = _run_model(cfg)

    return results
