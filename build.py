import os
import shutil

src_dir = r"F:\Projects\RUDWEAK"
build_dir = r"C:\Users\Administrator\AppData\Local\Temp\RUDWEAK_proper_build"
dest_folder = os.path.join(build_dir, "RUDWEAK")

if os.path.exists(build_dir):
    shutil.rmtree(build_dir)

os.makedirs(dest_folder)

for item in os.listdir(src_dir):
    if item in ['.git', '.gitignore', '.gitattributes', 'build.py', 'release_notes.txt', 'RUDWEAK_v1.0_Offline.zip']:
        continue
    
    s = os.path.join(src_dir, item)
    d = os.path.join(dest_folder, item)
    
    if os.path.isdir(s):
        shutil.copytree(s, d)
    else:
        shutil.copy2(s, d)

# Создаем архив
zip_path = os.path.join(src_dir, "RUDWEAK_v1.0_Offline")
shutil.make_archive(zip_path, 'zip', build_dir, "RUDWEAK")

print(f"Archive successfully created at {zip_path}.zip")
