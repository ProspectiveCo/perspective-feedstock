import glob
import os
import shutil
import platform

d = os.path.join(os.environ["SP_DIR"], "perspective")
os.makedirs(d, exist_ok=True)

os_name = platform.system().lower()
machine = platform.machine()
machine = machine if machine != "aarch64" else "arm64"
ext = "dll" if os_name == "windows" else "so"
arch = "x86_64" if platform.machine().lower() == "amd64"
dylib_name = f"{platform.system().lower()}-{arch}-libpsp.{ext}"

target_dir = os.environ.get("CARGO_TARGET_DIR", "target")

for ext_to_copy in ["so", "dylib", "dll", "pyd"]:
    for f in glob.glob(f"{target_dir}/**/libpsp.{ext_to_copy}", recursive=True):
        shutil.copy(f, os.path.join(d, dylib_name))

