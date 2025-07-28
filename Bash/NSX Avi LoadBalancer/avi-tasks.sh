#!/bin/bash

# ==============================================================================
# NSX-ALB API Configuration Script - Production Version
# Description: Creates Health Monitor, Pool, VsVip, and Virtual Service
# Features: Error handling, logging, rollback functionality
# ==============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==============================================================================
# LOGGING CONFIGURATION
# ==============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_DIR="/Users/ckremer/Desktop/nsx-alb"
readonly LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.*}_$(date +%Y%m%d_%H%M%S).log"
readonly DEBUG=${DEBUG:-false}

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}" 2>/dev/null || {
    echo "Warning: Cannot create log directory ${LOG_DIR}, using /tmp"
    readonly LOG_FILE="/tmp/${SCRIPT_NAME%.*}_$(date +%Y%m%d_%H%M%S).log"
}

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { [[ "${DEBUG}" == "true" ]] && log "DEBUG" "$@" || true; }

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================

# API Connection Settings
readonly BASE_URL="https://avi-01a.vi-universe.lab"
readonly AUTH_HEADER='Authorization: Basic #base64 Auth' 
readonly COOKIE_HEADER="Cookie: avi-sessionid=None; sessionid=None"
readonly CONTENT_TYPE="Content-Type: application/json"
readonly AVI_VERSION_HEADER="X-Avi-Version: 31.1.1"

# Common Infrastructure References
readonly CLOUD_NAME="nsx-01a"
readonly VRF_NAME="t1-avi-vip"
readonly CLOUD_REF="/api/cloud?name=${CLOUD_NAME}"
readonly VRF_REF="/api/vrfcontext?name=${VRF_NAME}"

# Health Monitor Configuration
readonly MONITOR_NAME="script-test-healthmon"
readonly MONITOR_TYPE="HEALTH_MONITOR_TCP"
readonly TCP_TIMEOUT=5
readonly SEND_INTERVAL=10
readonly RECEIVE_TIMEOUT=5
readonly SUCCESSFUL_CHECKS=2
readonly FAILED_CHECKS=2
readonly MONITOR_PORT=0

# Pool Configuration
readonly POOL_NAME="script-test-pool"
readonly DEFAULT_SERVER_PORT=443
readonly SERVER1_IP="10.0.0.11"
readonly SERVER2_IP="10.0.0.12"
readonly IP_TYPE="V4"
readonly LB_ALGORITHM="LB_ALGORITHM_ROUND_ROBIN"
readonly HEALTH_MONITOR_REF="/api/healthmonitor?name=${MONITOR_NAME}"

# VsVip Configuration
readonly VSVIP_NAME="script-test-vsvip"
readonly VIP_IP_ADDRESS="10.0.0.200"

# Virtual Service Configuration
readonly VS_NAME="script-test-vs"
readonly VS_TYPE="VS_TYPE_NORMAL"
readonly VS_PORT=6443
readonly VS_ENABLE_SSL=false
readonly VS_ENABLED=true
readonly APPLICATION_PROFILE_REF="/api/applicationprofile?name=System-L4-Application"
readonly NETWORK_PROFILE_REF="/api/networkprofile?name=System-TCP-Proxy"
readonly POOL_REF="/api/pool?name=${POOL_NAME}"
readonly VSVIP_REF="/api/vsvip?name=${VSVIP_NAME}"

# ==============================================================================
# ROLLBACK TRACKING
# ==============================================================================

# Array to track created objects for rollback
declare -a CREATED_OBJECTS=()
readonly ROLLBACK_ENABLED=${ROLLBACK_ENABLED:-true}

# Add object to rollback tracking
track_created_object() {
    local object_type="$1"
    local object_name="$2"
    CREATED_OBJECTS+=("${object_type}:${object_name}")
    log_debug "Tracking created object: ${object_type}:${object_name}"
}

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Function to make API calls with error handling
make_api_call() {
    local endpoint="$1"
    local data="$2"
    local description="$3"
    local object_type="$4"
    local object_name="$5"
    
    log_info "Creating ${description}..."
    log_debug "API Endpoint: ${BASE_URL}${endpoint}"
    log_debug "Request Data: ${data}"
    
    local response_file=$(mktemp)
    local http_code
    
    if http_code=$(curl --insecure --location --silent --show-error \
        --write-out "%{http_code}" \
        --output "${response_file}" \
        "${BASE_URL}${endpoint}" \
        --header "${CONTENT_TYPE}" \
        --header "${AVI_VERSION_HEADER}" \
        --header "${AUTH_HEADER}" \
        --header "${COOKIE_HEADER}" \
        --data "${data}"); then
        
        log_debug "HTTP Response Code: ${http_code}"
        log_debug "Response Body: $(cat "${response_file}")"
        
        if [[ "${http_code}" =~ ^2[0-9][0-9]$ ]]; then
            log_info "${description} created successfully (HTTP: ${http_code})"
            track_created_object "${object_type}" "${object_name}"
            rm -f "${response_file}"
            return 0
        else
            log_error "API call failed with HTTP code: ${http_code}"
            log_error "Response: $(cat "${response_file}")"
            rm -f "${response_file}"
            return 1
        fi
    else
        log_error "Failed to create ${description} - curl command failed"
        rm -f "${response_file}"
        return 1
    fi
}

# Function to delete an object (for rollback)
delete_object() {
    local object_type="$1"
    local object_name="$2"
    
    local endpoint
    case "${object_type}" in
        "virtualservice") endpoint="/api/virtualservice?name=${object_name}" ;;
        "vsvip") endpoint="/api/vsvip?name=${object_name}" ;;
        "pool") endpoint="/api/pool?name=${object_name}" ;;
        "healthmonitor") endpoint="/api/healthmonitor?name=${object_name}" ;;
        *) 
            log_error "Unknown object type for deletion: ${object_type}"
            return 1
            ;;
    esac
    
    log_info "Deleting ${object_type}: ${object_name}"
    
    if curl --insecure --location --silent --show-error --fail \
        -X DELETE \
        "${BASE_URL}${endpoint}" \
        --header "${AVI_VERSION_HEADER}" \
        --header "${AUTH_HEADER}" \
        --header "${COOKIE_HEADER}"; then
        log_info "Successfully deleted ${object_type}: ${object_name}"
        return 0
    else
        log_warn "Failed to delete ${object_type}: ${object_name} (may not exist)"
        return 1
    fi
}

# Rollback function - deletes created objects in reverse order
rollback_changes() {
    if [[ "${ROLLBACK_ENABLED}" != "true" ]]; then
        log_info "Rollback is disabled, skipping cleanup"
        return 0
    fi
    
    if [[ ${#CREATED_OBJECTS[@]} -eq 0 ]]; then
        log_info "No objects to rollback"
        return 0
    fi
    
    log_warn "Starting rollback process..."
    log_info "Rolling back ${#CREATED_OBJECTS[@]} created objects"
    
    # Delete in reverse order (last created first)
    for ((i=${#CREATED_OBJECTS[@]}-1; i>=0; i--)); do
        local object_info="${CREATED_OBJECTS[i]}"
        local object_type="${object_info%%:*}"
        local object_name="${object_info##*:}"
        
        delete_object "${object_type}" "${object_name}"
        sleep 2  # Brief pause between deletions
    done
    
    log_info "Rollback process completed"
}

# Error handler - called on script failure
error_handler() {
    local exit_code=$?
    local line_number=$1
    
    log_error "Script failed at line ${line_number} with exit code ${exit_code}"
    log_error "Rolling back changes..."
    
    rollback_changes
    
    log_error "Script execution failed. Check log file: ${LOG_FILE}"
    exit ${exit_code}
}

# Function to validate required variables
validate_config() {
    local required_vars=(
        "BASE_URL" "MONITOR_NAME" "POOL_NAME" "VSVIP_NAME" "VS_NAME"
        "SERVER1_IP" "SERVER2_IP" "VIP_IP_ADDRESS"
    )
    
    log_info "Validating configuration..."
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Required variable ${var} is not set"
            return 1
        fi
    done
    
    log_info "Configuration validation passed"
    return 0
}

# Function to test API connectivity
test_api_connectivity() {
    log_info "Testing API connectivity to ${BASE_URL}..."
    
    local response_file=$(mktemp)
    local http_code
    
    if http_code=$(curl --insecure --location --silent --show-error \
        --connect-timeout 10 \
        --max-time 30 \
        --write-out "%{http_code}" \
        --output "${response_file}" \
        "${BASE_URL}/api/tenant" \
        --header "${AVI_VERSION_HEADER}" \
        --header "${AUTH_HEADER}" \
        --header "${COOKIE_HEADER}"); then
        
        if [[ "${http_code}" =~ ^2[0-9][0-9]$ ]]; then
            log_info "API connectivity test successful (HTTP: ${http_code})"
            rm -f "${response_file}"
            return 0
        else
            log_error "API connectivity test failed with HTTP code: ${http_code}"
            log_error "Response: $(cat "${response_file}")"
            rm -f "${response_file}"
            return 1
        fi
    else
        log_error "API connectivity test failed - unable to reach ${BASE_URL}"
        rm -f "${response_file}"
        return 1
    fi
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    # Set up error handling
    trap 'error_handler ${LINENO}' ERR
    
    log_info "=========================================="
    log_info "Starting NSX-ALB configuration script"
    log_info "Script: ${SCRIPT_NAME}"
    log_info "Log file: ${LOG_FILE}"
    log_info "Target: ${BASE_URL}"
    log_info "Debug mode: ${DEBUG}"
    log_info "Rollback enabled: ${ROLLBACK_ENABLED}"
    log_info "=========================================="
    
    # Validate configuration
    validate_config || exit 1
    
    # Test API connectivity
    test_api_connectivity || exit 1
    
    # Create Health Monitor
    local health_monitor_data='{
        "name": "'${MONITOR_NAME}'",
        "type": "'${MONITOR_TYPE}'",
        "tcp_monitor": {
            "timeout": '${TCP_TIMEOUT}'
        },
        "send_interval": '${SEND_INTERVAL}',
        "receive_timeout": '${RECEIVE_TIMEOUT}',
        "successful_checks": '${SUCCESSFUL_CHECKS}',
        "failed_checks": '${FAILED_CHECKS}',
        "monitor_port": '${MONITOR_PORT}'
    }'
    
    make_api_call "/api/healthmonitor" "${health_monitor_data}" "Health Monitor" "healthmonitor" "${MONITOR_NAME}" || exit 1
    
    # Create Pool
    local pool_data='{
        "name": "'${POOL_NAME}'",
        "default_server_port": '${DEFAULT_SERVER_PORT}',
        "cloud_ref": "'${CLOUD_REF}'",
        "vrf_ref": "'${VRF_REF}'",
        "servers": [
            {
                "ip": {
                    "addr": "'${SERVER1_IP}'",
                    "type": "'${IP_TYPE}'"
                }
            },
            {
                "ip": {
                    "addr": "'${SERVER2_IP}'",
                    "type": "'${IP_TYPE}'"
                }
            }
        ],
        "health_monitor_refs": [
            "'${HEALTH_MONITOR_REF}'"
        ],
        "lb_algorithm": "'${LB_ALGORITHM}'"
    }'
    
    make_api_call "/api/pool" "${pool_data}" "Pool" "pool" "${POOL_NAME}" || exit 1
    
    # Create VsVip
    local vsvip_data='{
        "name": "'${VSVIP_NAME}'",
        "vip": [
            {
                "ip_address": {
                    "addr": "'${VIP_IP_ADDRESS}'",
                    "type": "'${IP_TYPE}'"
                }
            }
        ],
        "cloud_ref": "'${CLOUD_REF}'",
        "vrf_context_ref": "'${VRF_REF}'"
    }'
    
    make_api_call "/api/vsvip" "${vsvip_data}" "VsVip" "vsvip" "${VSVIP_NAME}" || exit 1
    
    # Create Virtual Service
    local vs_data='{
        "name": "'${VS_NAME}'",
        "type": "'${VS_TYPE}'",
        "cloud_ref": "'${CLOUD_REF}'",
        "vrf_context_ref": "'${VRF_REF}'",
        "services": [
            {
                "port": '${VS_PORT}',
                "enable_ssl": '${VS_ENABLE_SSL}'
            }
        ],
        "enabled": '${VS_ENABLED}',
        "application_profile_ref": "'${APPLICATION_PROFILE_REF}'",
        "network_profile_ref": "'${NETWORK_PROFILE_REF}'",
        "pool_ref": "'${POOL_REF}'",
        "vsvip_ref": "'${VSVIP_REF}'"
    }'
    
    make_api_call "/api/virtualservice" "${vs_data}" "Virtual Service" "virtualservice" "${VS_NAME}" || exit 1
    
    log_info "=========================================="
    log_info "NSX-ALB configuration completed successfully!"
    log_info "Created components:"
    log_info "  - Health Monitor: ${MONITOR_NAME}"
    log_info "  - Pool: ${POOL_NAME}"
    log_info "  - VsVip: ${VSVIP_NAME}"
    log_info "  - Virtual Service: ${VS_NAME}"
    log_info "=========================================="
    log_info "Log file saved to: ${LOG_FILE}"
}

# Script usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

NSX-ALB Configuration Script - Creates Health Monitor, Pool, VsVip, and Virtual Service

OPTIONS:
    -h, --help          Show this help message
    -d, --debug         Enable debug logging
    --no-rollback       Disable rollback on failure
    --dry-run           Validate configuration without making changes

ENVIRONMENT VARIABLES:
    DEBUG=true          Enable debug mode
    ROLLBACK_ENABLED=false    Disable rollback functionality

EXAMPLES:
    $0                  # Normal execution
    $0 --debug          # Debug mode
    $0 --no-rollback    # Disable rollback
    DEBUG=true $0       # Environment variable debug

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -d|--debug)
            readonly DEBUG=true
            shift
            ;;
        --no-rollback)
            readonly ROLLBACK_ENABLED=false
            shift
            ;;
        --dry-run)
            log_info "Dry-run mode: Configuration validation only"
            validate_config && log_info "Configuration is valid"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Execute main function
main "$@"