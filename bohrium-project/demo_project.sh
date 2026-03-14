#!/bin/bash
# Bohrium Project Management Demo Script
# Prerequisites: bohr CLI installed, ACCESS_KEY set

set -e

# ============================================================
# 1. List projects
# ============================================================
echo "=== List all projects ==="
bohr project list

echo ""
echo "=== List projects (JSON) ==="
bohr project list --json

# ============================================================
# 2. Create a project
# ============================================================
echo ""
echo "=== Create project ==="
# bohr project create -n "my-research-group"

echo "=== Create project with budget limits ==="
# bohr project create -n "workshop-2026" -m 5000 -t 20000

# ============================================================
# 3. Get detailed project list via API (with costs, members)
# ============================================================
echo ""
echo "=== Detailed project list (API) ==="
python3 -c "
import os, requests
AK = os.environ.get('ACCESS_KEY', '')
r = requests.get('https://openapi.dp.tech/openapi/v1/project/list',
    headers={'accessKey': AK})
data = r.json().get('data', {})
for p in data.get('items', [])[:5]:
    print(f\"  ID: {p.get('id')}, Name: {p.get('name')}, \
Total Cost: {p.get('totalCost')}, Members: {p.get('userCount')}, \
Role: {'Creator' if p.get('projectRole') == 1 else 'Member'}\")
"

# ============================================================
# 4. Member management via API
# ============================================================
echo ""
echo "=== View project members ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.get('https://openapi.dp.tech/openapi/v1/project/<PROJECT_ID>/users',
#     headers={'accessKey': AK})
# for u in r.json().get('data', {}).get('items', []):
#     role = 'Admin' if u.get('projectRole') == 1 else 'Member'
#     print(f\"  {u.get('userName')} ({u.get('email')}) - {role} - Cost: {u.get('cost')}\")
# "

echo "=== Add member by email ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v1/project/add_user',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={'projectId': <PROJECT_ID>, 'email': 'colleague@example.com'})
# print(r.json())
# "

echo "=== Promote member to admin ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v1/project/manager/add',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={'projectId': <PROJECT_ID>, 'userId': <USER_ID>})
# print(r.json())
# "

# ============================================================
# 5. Budget management via API
# ============================================================
echo ""
echo "=== Set project cost limit ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v1/project/set_cost_limit',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={'projectId': <PROJECT_ID>, 'costLimit': 10000})
# print(r.json())
# "

echo "=== Rename project ==="
# python3 -c "
# import os, requests
# AK = os.environ.get('ACCESS_KEY', '')
# r = requests.post('https://openapi.dp.tech/openapi/v1/project/set_name',
#     headers={'accessKey': AK, 'Content-Type': 'application/json'},
#     json={'projectId': <PROJECT_ID>, 'name': 'new-project-name'})
# print(r.json())
# "

# ============================================================
# 6. Delete project (IRREVERSIBLE!)
# ============================================================
echo ""
echo "=== Delete project (use with caution!) ==="
# bohr project delete <PROJECT_ID>

echo ""
echo "Demo complete. Uncomment commands to run them."
