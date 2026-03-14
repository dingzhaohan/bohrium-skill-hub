#!/bin/bash
# Bohrium Image Management Demo Script
# Prerequisites: bohr CLI installed, ACCESS_KEY set

set -e

# ============================================================
# 1. List custom images
# ============================================================
echo "=== List custom images ==="
bohr image list

echo ""
echo "=== List custom images (JSON) ==="
bohr image list --json

# ============================================================
# 2. List public images by software type
# ============================================================
echo ""
echo "=== List DeePMD-kit public images ==="
bohr image list -t "DeePMD-kit"

echo ""
echo "=== List LAMMPS public images ==="
bohr image list -t "LAMMPS"

echo ""
echo "=== List basic images ==="
bohr image list -t "Basic Image"

# ============================================================
# 3. Search public image versions via API
# ============================================================
echo ""
echo "=== Search public image versions (keyword: deepmd) ==="
python3 -c "
import os, requests
AK = os.environ.get('ACCESS_KEY', '')
r = requests.get('https://openapi.dp.tech/openapi/v2/image/public/version/search',
    headers={'accessKey': AK},
    params={'keyword': 'deepmd', 'page': 1, 'pageSize': 5})
data = r.json().get('data', {})
for item in data.get('items', []):
    print(f\"  {item.get('imageName')}:{item.get('version')} - {item.get('url')}\")
"

# ============================================================
# 4. Pull image to local Docker
# ============================================================
echo ""
echo "=== Pull image via bohr CLI ==="
# Requires Docker Desktop running
# bohr image pull registry.dp.tech/dptech/deepmd-kit:3.0.0b3-cuda12.1

echo "=== Pull image via Docker CLI (alternative) ==="
# docker login registry.bohrium.dp.tech
# docker pull registry.bohrium.dp.tech/dptech/ubuntu:22.04-py3.10-intel2022

# ============================================================
# 5. Build custom image from Dockerfile via API
# ============================================================
echo ""
echo "=== Build custom image from Dockerfile ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v2/image/private',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={
#         'name': 'my-custom-image',
#         'projectId': ${PROJECT_ID},
#         'device': 'container',
#         'desc': 'Custom image with my packages',
#         'buildType': 1,
#         'dockerfile': 'FROM registry.dp.tech/dptech/ubuntu:20.04-py3.10-cuda11.6\nRUN pip install torch numpy'
#     })
# print(r.json())
# "

# ============================================================
# 6. Delete custom images
# ============================================================
echo ""
echo "=== Delete custom image ==="
# bohr image delete <IMAGE_ID>
# bohr image delete <ID1> <ID2>    # batch delete

echo ""
echo "Demo complete. Uncomment commands to run them."
