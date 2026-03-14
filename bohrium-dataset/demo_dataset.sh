#!/bin/bash
# Bohrium Dataset Management Demo Script
# Prerequisites: bohr CLI installed, ACCESS_KEY set

set -e

# ============================================================
# 1. List datasets
# ============================================================
echo "=== List all datasets ==="
bohr dataset list

echo ""
echo "=== List datasets (JSON, top 5) ==="
bohr dataset list -n 5 --json

echo ""
echo "=== Filter by project ID ==="
# bohr dataset list -p ${PROJECT_ID}

echo ""
echo "=== Search by title ==="
# bohr dataset list -t "my-dataset"

# ============================================================
# 2. Create dataset (upload data)
# ============================================================
echo ""
echo "=== Create dataset (upload local data) ==="
# bohr dataset create \
#   -n "training-data" \
#   -p "training-data" \
#   -i ${PROJECT_ID} \
#   -l "/path/to/local/data" \
#   -m "Training dataset for DeePMD-kit"

# If upload is interrupted, re-run the same command and enter 'y' to resume

# ============================================================
# 3. Use dataset in job submission
# ============================================================
echo ""
echo "=== Create job.json with dataset mounting ==="
cat > /tmp/demo_dataset_job.json << 'EOF'
{
  "job_name": "job-with-dataset",
  "command": "ls /bohr/training-data/v1 && python train.py",
  "log_file": "train.log",
  "backward_files": ["model.pt"],
  "project_id": 154,
  "machine_type": "c4_m15_1 * NVIDIA T4",
  "job_type": "container",
  "image_address": "registry.dp.tech/dptech/deepmd-kit:2.1.5-cuda11.6",
  "dataset_path": ["/bohr/training-data/v1"]
}
EOF
echo "job.json created at /tmp/demo_dataset_job.json"
echo "Submit with: bohr job submit -i /tmp/demo_dataset_job.json -p ./input/"

# ============================================================
# 4. Check quota via API
# ============================================================
echo ""
echo "=== Check dataset quota ==="
python3 -c "
import os, requests
AK = os.environ.get('ACCESS_KEY', '')
r = requests.get('https://openapi.dp.tech/openapi/v1/ds/quota/check',
    headers={'accessKey': AK},
    params={'projectId': ${PROJECT_ID:-154}})
data = r.json().get('data', {})
print(f\"  Quota limit: {data.get('limit')}, Used: {data.get('used')}, Available: {data.get('result')}\")
"

# ============================================================
# 5. Get dataset details and versions via API
# ============================================================
echo ""
echo "=== Get dataset details ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# BASE = 'https://openapi.dp.tech/openapi/v1/ds'
# r = requests.get(f'{BASE}/<DATASET_ID>', headers={'accessKey': AK})
# print(r.json())
# "

echo "=== Get dataset versions ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# BASE = 'https://openapi.dp.tech/openapi/v1/ds'
# r = requests.get(f'{BASE}/<DATASET_ID>/version', headers={'accessKey': AK})
# for v in r.json().get('data', {}).get('items', []):
#     print(f\"  Version {v.get('version')}: {v.get('totalSize')} bytes, path: {v.get('datasetPath')}\")
# "

# ============================================================
# 6. Delete dataset
# ============================================================
echo ""
echo "=== Delete dataset ==="
# bohr dataset delete <DATASET_ID>
# bohr dataset delete <ID1> <ID2>    # batch delete

echo ""
echo "Demo complete. Uncomment commands to run them."
