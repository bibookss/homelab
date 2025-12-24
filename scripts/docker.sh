#!/bin/bash
# Docker Management Script for Homelab Services
# Manages all Docker containers and services

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$HOMELAB_DIR/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to ensure homelab network exists
ensure_network() {
    if ! docker network ls | grep -q homelab; then
        print_info "Creating homelab network..."
        docker network create homelab
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
    
    print_info "Starting $service..."
    cd "$service_dir"
    
    # Check for .env file
    if [[ ! -f .env ]] && [[ -f env.example ]]; then
        print_warn ".env file not found, copying from env.example"
        cp env.example .env
        print_warn "Please review and update .env file with your settings"
    fi
    
    docker compose up -d
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
    docker compose down
    print_info "$service stopped"
}

# Function to restart a service
restart_service() {
    local service=$1
    print_info "Restarting $service..."
    stop_service "$service"
    start_service "$service"
}

# Function to show logs
show_logs() {
    local service=$1
    local service_dir="$DOCKER_DIR/$service"
    
    if [[ ! -d "$service_dir" ]]; then
        print_error "Service '$service' not found"
        return 1
    fi
    
    cd "$service_dir"
    docker compose logs -f
}

# Function to show status
show_status() {
    print_info "Homelab Services Status:"
    echo ""
    docker ps --filter "name=postgres|minio|airflow|qbittorrent|portainer" \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to wait for postgres to be ready
wait_for_postgres() {
    print_info "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec postgres pg_isready -U postgres &> /dev/null; then
            print_info "PostgreSQL is ready"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    print_warn "PostgreSQL may not be ready, but continuing..."
    return 1
}

# Function to setup all services
setup_all() {
    print_info "Setting up all homelab services..."
    ensure_network
    
    # Start postgres first
    if [[ -d "$DOCKER_DIR/postgres" ]]; then
        start_service "postgres"
        wait_for_postgres
    fi
    
    # Start other services
    local services=("minio" "portainer" "qbittorrent" "airflow")
    
    for service in "${services[@]}"; do
        if [[ -d "$DOCKER_DIR/$service" ]]; then
            start_service "$service"
            sleep 2
        fi
    done
    
    print_info "All services setup complete!"
    show_status
}

# Function to stop all services
stop_all() {
    print_info "Stopping all homelab services..."
    
    local services=("airflow" "qbittorrent" "portainer" "minio" "postgres")
    
    for service in "${services[@]}"; do
        if [[ -d "$DOCKER_DIR/$service" ]]; then
            stop_service "$service" || true
        fi
    done
    
    print_info "All services stopped"
}

# Main command handler
case "${1:-}" in
    start)
        check_docker
        ensure_network
        if [[ -n "${2:-}" ]]; then
            start_service "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    stop)
        check_docker
        if [[ -n "${2:-}" ]]; then
            stop_service "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    restart)
        check_docker
        ensure_network
        if [[ -n "${2:-}" ]]; then
            restart_service "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    logs)
        check_docker
        if [[ -n "${2:-}" ]]; then
            show_logs "$2"
        else
            print_error "Please specify a service: postgres, minio, airflow, qbittorrent, portainer"
            exit 1
        fi
        ;;
    status)
        check_docker
        show_status
        ;;
    setup)
        check_docker
        setup_all
        ;;
    stop-all)
        check_docker
        stop_all
        ;;
    *)
        echo "Homelab Docker Management Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|logs|status|setup|stop-all} [service]"
        echo ""
        echo "Commands:"
        echo "  start <service>    Start a specific service"
        echo "  stop <service>     Stop a specific service"
        echo "  restart <service>  Restart a specific service"
        echo "  logs <service>     Show logs for a service"
        echo "  status             Show status of all services"
        echo "  setup              Setup and start all services"
        echo "  stop-all           Stop all services"
        echo ""
        echo "Services:"
        echo "  postgres, minio, airflow, qbittorrent, portainer"
        exit 1
        ;;
esac

