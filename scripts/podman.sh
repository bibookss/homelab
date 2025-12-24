#!/bin/bash
# Podman Management Script for Homelab Services
# Alternative to Docker using Podman

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$HOMELAB_DIR/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Podman is installed
check_podman() {
    if ! command -v podman &> /dev/null; then
        print_error "Podman is not installed"
        echo "Install with: brew install podman (macOS) or your package manager (Linux)"
        exit 1
    fi
    
    if ! podman info &> /dev/null; then
        print_error "Podman is not running"
        exit 1
    fi
}

# Function to ensure homelab network exists
ensure_network() {
    if ! podman network ls | grep -q homelab; then
        print_info "Creating homelab network..."
        podman network create homelab
    fi
}

# Function to start a service
start_service() {
    local service=$1
    local service_dir="$DOCKER_DIR/$service"
    
    if [[ ! -d "$service_dir" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    print_info "Starting $service with Podman..."
    cd "$service_dir"
    
    # Check for .env file
    if [[ ! -f .env ]] && [[ -f env.example ]]; then
        print_warn ".env file not found, copying from env.example"
        cp env.example .env
        print_warn "Please review and update .env file with your settings"
    fi
    
    podman compose up -d
    print_info "$service started"
}

# Function to stop a service
stop_service() {
    local service=$1
    local service_dir="$DOCKER_DIR/$service"
    
    if [[ ! -d "$service_dir" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    print_info "Stopping $service..."
    cd "$service_dir"
    podman compose down
    print_info "$service stopped"
}

# Function to show status
show_status() {
    print_info "Homelab Services Status (Podman):"
    echo ""
    podman ps --filter "name=postgres|minio|airflow|qbittorrent|portainer" \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main command handler
case "${1:-}" in
    start)
        check_podman
        ensure_network
        if [[ -n "${2:-}" ]]; then
            start_service "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    stop)
        check_podman
        if [[ -n "${2:-}" ]]; then
            stop_service "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    status)
        check_podman
        show_status
        ;;
    *)
        echo "Homelab Podman Management Script"
        echo ""
        echo "Usage: $0 {start|stop|status} [service]"
        echo ""
        echo "Commands:"
        echo "  start <service>    Start a specific service"
        echo "  stop <service>     Stop a specific service"
        echo "  status             Show status of all services"
        echo ""
        echo "Services:"
        echo "  postgres, minio, airflow, qbittorrent, portainer"
        exit 1
        ;;
esac

