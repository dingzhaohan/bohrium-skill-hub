#!/bin/bash
# Bohrium Node Management Demo Script
# Prerequisites: bohr CLI installed, ACCESS_KEY set

set -e

# ============================================================
# 1. List nodes
# ============================================================
echo "=== List all nodes ==="
bohr node list

echo ""
echo "=== List running nodes (JSON) ==="
bohr node list -s --json

echo ""
echo "=== Quick list (ID and name only) ==="
bohr node list -q

# ============================================================
# 2. Create a node (interactive)
# ============================================================
echo ""
echo "=== Create node (interactive, will prompt for choices) ==="
echo "Steps: Project -> Image -> Machine Type -> Name -> Disk Size"
# Uncomment to run:
# bohr node create

# ============================================================
# 3. Create node via API (non-interactive, for automation)
# ============================================================
echo ""
echo "=== Create node via API (non-interactive) ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v1/node/add',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={
#         'projectId': ${PROJECT_ID},
#         'name': 'demo-node',
#         'imageId': 2168,
#         'machineConfig': {'type': 0, 'value': 388, 'label': 'c2_m4_cpu'},
#         'diskSize': 20
#     })
# print(r.json())
# "

# ============================================================
# 4. Connect to node
# ============================================================
echo ""
echo "=== Connect to node via SSH (passwordless) ==="
# bohr node connect <NODE_ID>

# ============================================================
# 5. Query resources and pricing
# ============================================================
echo ""
echo "=== Query available resources ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.get('https://openapi.dp.tech/openapi/v1/node/resources',
#     headers={'accessKey': AK})
# data = r.json().get('data', {})
# print('Available disks:', data.get('disks', []))
# print('CPU options:', len(data.get('cpuList', [])))
# print('GPU options:', len(data.get('gpuList', [])))
# "

echo "=== Query resource price ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.get('https://openapi.dp.tech/openapi/v1/node/resources/price',
#     headers={'accessKey': AK},
#     params={'skuId': 388, 'projectId': ${PROJECT_ID}})
# print('Price:', r.json().get('data', {}).get('price'), 'RMB/hour')
# "

# ============================================================
# 6. Stop and delete nodes
# ============================================================
echo ""
echo "=== Stop node (pause billing, data preserved) ==="
# bohr node stop <NODE_ID>

echo "=== Delete node (irreversible) ==="
# bohr node delete <NODE_ID>

# ============================================================
# 7. Node details via API (get SSH password)
# ============================================================
echo ""
echo "=== Get node details (SSH password) ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.get('https://openapi.dp.tech/openapi/v1/node/<MACHINE_ID>',
#     headers={'accessKey': AK})
# d = r.json().get('data', {})
# print(f\"IP: {d.get('ip')}, User: {d.get('nodeUser')}, Password: {d.get('nodePwd')}\")
# print(f\"Domain: {d.get('domainName')}\")
# "

echo ""
echo "Demo complete. Uncomment commands to run them."
