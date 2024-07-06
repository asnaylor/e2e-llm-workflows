#!/usr/bin/env bash

# Start Ray Cluster Head
# By Andrew Naylor - Jul 24

# Define default values
hf_token=""
hf_home=$SCRATCH/huggingface/

SHIFTER_IMAGE=vllm/vllm-openai:v0.5.0
SHIFTER_MODULES="gpu,nccl-2.18"

metrics=true
PROM_IMAGE="prom/prometheus:v2.42.0"
GRAFANA_IMAGE="grafana/grafana-oss:9.4.3"

RAY_HEAD_PORT=6379
RAY_DASHBOARD_PORT=8265

# Function to display help message
help_function() {
  echo "Usage: $0 [--hf_token <value>] [--no_metrics]"
  echo ""
  echo "Optional arguments:"
  echo "  --hf_token <value>  : Give a huggingface token"
  echo "  --no_metrics : Turn off metrics setup"
  echo ""
  echo "  -h, --help     : Display this help message"
  exit 1
}

#Trap function to clean up shifter containers
function cleanup {
    echo "-- Cleaning up cluster --"
    kill $(pgrep -P $SHIFTER_RAY_PID) && sleep 5
    kill -9 $(pgrep -P $SHIFTER_RAY_PID)
    kill $SHIFTER_RAY_PID
    if [[ "$metrics" == "true" ]]; then
        echo "-- Cleaning up Granfana + Prometheus --"
        kill $SHIFTER_PROM_PID
        kill $SHIFTER_GF_PID
    fi
    echo "-- Finished --"
}
trap cleanup EXIT

# Process arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --hf_token)
      shift
      hf_token="$1"
      ;;
    --no_metrics)
      metrics=false
      ;;
    -h|--help)
      help_function
      ;;
    *)
      echo "Error: Unknown argument '$1'"
      help_function
      ;;
  esac
  shift
done

# Setup Ray Head
echo "-- Setup Ray Head --"
if [[ -n "$hf_token" ]]; then
  export HF_TOKEN=$hf_token
fi
export HF_HOME=$hf_home

jupyter_base="https://jupyter.nersc.gov/user/$USER/perlmutter-login-node-base/proxy/"
gf_root_url="${jupyter_base}3000"
export RAY_GRAFANA_IFRAME_HOST=$gf_root_url
METRICS_DIR=$SCRATCH/ray_cluster_metrics

RAY_HEAD_IP=$(hostname)
shifter --image=$SHIFTER_IMAGE --module=$SHIFTER_MODULES \
    ray start --head --node-ip-address=$RAY_HEAD_IP --port=$RAY_HEAD_PORT \
    --num-cpus 0 --num-gpus 0 \
    --dashboard-port=$RAY_DASHBOARD_PORT --block &
SHIFTER_RAY_PID=$!

# Setup Metrics
if [[ "$metrics" == "true" ]]; then
    sleep 30
    echo "-- Setting up metrics --"
    
    ## Start Prometheus
    mkdir -p $METRICS_DIR/prometheus
    shifter --image=$PROM_IMAGE --module=None --volume=$METRICS_DIR/prometheus:/prometheus \
            /bin/prometheus --config.file=/tmp/ray/session_latest/metrics/prometheus/prometheus.yml --storage.tsdb.path=/prometheus &
    SHIFTER_PROM_PID=$!

    ## Start Grafana
    mkdir -p $METRICS_DIR/grafana
    shifter --image=$GRAFANA_IMAGE --module=None --volume=$METRICS_DIR/grafana:/grafana --entrypoint \
            --env GF_PATHS_DATA=/grafana --env GF_PATHS_PLUGINS=/grafana/plugins --env GF_PATHS_CONFIG=/tmp/ray/session_latest/metrics/grafana/grafana.ini \
            --env GF_PATHS_PROVISIONING=/tmp/ray/session_latest/metrics/grafana/provisioning --env GF_SERVER_ROOT_URL=${gf_root_url}/ &
    SHIFTER_GF_PID=$!
fi

sleep 10
echo "-- Running Ray Head Node --"
echo " To create ray workers on slurm you can:"
echo "     sbatch <slurm args> start_ray_workers.sh ${RAY_HEAD_IP}:${RAY_HEAD_PORT}"

wait