#!/bin/bash
# Bohrium Job Management Demo Script
# Prerequisites: bohr CLI installed, ACCESS_KEY set

set -e

# ============================================================
# 1. List jobs
# ============================================================
echo "=== List recent 5 jobs ==="
bohr job list -n 5

echo ""
echo "=== List running jobs (JSON) ==="
bohr job list -r --json

# ============================================================
# 2. Submit a DeePMD-kit training job (command-line args)
# ============================================================
echo ""
echo "=== Submit DeePMD-kit job via CLI args ==="
bohr job submit \
  -m "registry.dp.tech/dptech/deepmd-kit:2.1.5-cuda11.6" \
  -t "c4_m15_1 * NVIDIA T4" \
  -c "cd se_e2_a && dp train input.json > tmp_log 2>&1 && dp freeze -o graph.pb" \
  -p ./Bohrium_DeePMD-kit_example/ \
  --project_id ${PROJECT_ID} \
  -n "deepmd-demo"

# ============================================================
# 3. Submit via job.json config file
# ============================================================
echo ""
echo "=== Create job.json ==="
cat > /tmp/demo_job.json << 'JOBEOF'
{
  "job_name": "lammps-demo",
  "command": "mpirun -n 32 lmp_mpi -i in.shear > log",
  "log_file": "log",
  "backward_files": [],
  "project_id": ${PROJECT_ID},
  "machine_type": "c32_m64_cpu",
  "job_type": "container",
  "image_address": "registry.dp.tech/dptech/lammps:29Sep2021",
  "max_run_time": 60,
  "max_reschedule_times": 1
}
JOBEOF

echo "=== Submit LAMMPS job via config file ==="
# bohr job submit -i /tmp/demo_job.json -p ./Bohrium_LAMMPS_example/

# ============================================================
# 4. Submit with auto-download results
# ============================================================
echo ""
echo "=== Submit with auto-download to /personal ==="
# bohr job submit -i /tmp/demo_job.json -p ./input/ -r /personal/results

# ============================================================
# 5. Job group workflow
# ============================================================
echo ""
echo "=== Create job group ==="
# bohr job_group create -n "batch-experiment" -p ${PROJECT_ID}
# Returns: job_group_id

echo "=== Submit multiple jobs to same group ==="
# bohr job submit -m "registry.dp.tech/dptech/deepmd-kit:2.1.5-cuda11.6" \
#   -t "c4_m15_1 * NVIDIA T4" -c "python run1.py" -p ./exp1/ \
#   --project_id ${PROJECT_ID} -g <job_group_id>

# bohr job submit -m "registry.dp.tech/dptech/deepmd-kit:2.1.5-cuda11.6" \
#   -t "c4_m15_1 * NVIDIA T4" -c "python run2.py" -p ./exp2/ \
#   --project_id ${PROJECT_ID} -g <job_group_id>

# ============================================================
# 6. Monitor and manage jobs
# ============================================================
echo ""
echo "=== Describe a job ==="
# bohr job describe -j <JOB_ID> --json

echo "=== View job log ==="
# bohr job log -j <JOB_ID>

echo "=== Download job log to local ==="
# bohr job log -j <JOB_ID> -o ./logs/

echo "=== Download job results ==="
# bohr job download -j <JOB_ID> -o ./results/

# ============================================================
# 7. Terminate / Kill / Delete
# ============================================================
echo ""
echo "=== Terminate (save results, status -> completed) ==="
# bohr job terminate <JOB_ID>

echo "=== Kill (no results saved, job record kept) ==="
# bohr job kill <JOB_ID>

echo "=== Delete (remove everything) ==="
# bohr job delete <JOB_ID>

echo ""
echo "=== Job group operations ==="
# bohr job_group list -n 5 --json
# bohr job_group terminate <GROUP_ID>
# bohr job_group download -j <GROUP_ID> -o ./group_results/

echo ""
echo "Demo complete. Uncomment commands to run them."
