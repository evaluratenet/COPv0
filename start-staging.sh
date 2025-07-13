#!/bin/bash

# Circle of Peers Staging Environment Startup Script
# Production-like environment for testing and development

set -e

echo "🚀 Starting Circle of Peers Staging Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Load environment variables
load_environment() {
    print_status "Loading environment variables..."
    
    if [ ! -f "env.staging" ]; then
        print_warning "env.staging file not found. Using default values."
        export POSTGRES_PASSWORD=discourse_password
        export OPENAI_API_KEY=your_openai_api_key_here
        export DISCOURSE_API_KEY=your_discourse_api_key_here
        export GRAFANA_PASSWORD=secure_grafana_password_2024
    else
        export $(cat env.staging | grep -v '^#' | xargs)
    fi
    
    print_success "Environment variables loaded"
}

# Create SSL certificates for staging
setup_ssl() {
    print_status "Setting up SSL certificates for staging..."
    
    if [ ! -f "ssl/cert.pem" ] || [ ! -f "ssl/key.pem" ]; then
        print_warning "SSL certificates not found. Creating self-signed certificates for staging..."
        
        mkdir -p ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ssl/key.pem \
            -out ssl/cert.pem \
            -subj "/C=US/ST=State/L=City/O=Circle of Peers/CN=staging.circleofpeers.net"
        
        print_success "Self-signed SSL certificates created"
    else
        print_success "SSL certificates found"
    fi
}

# Start services
start_services() {
    print_status "Starting services with production-like configuration..."
    
    # Stop any existing containers
    docker-compose -f docker-compose.staging.yml down --remove-orphans
    
    # Start services
    docker-compose -f docker-compose.staging.yml up -d
    
    print_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for PostgreSQL
    print_status "Waiting for PostgreSQL..."
    until docker-compose -f docker-compose.staging.yml exec -T postgres pg_isready -U discourse; do
        sleep 2
    done
    print_success "PostgreSQL is ready"
    
    # Wait for Redis
    print_status "Waiting for Redis..."
    until docker-compose -f docker-compose.staging.yml exec -T redis redis-cli ping; do
        sleep 2
    done
    print_success "Redis is ready"
    
    # Wait for AI Service
    print_status "Waiting for AI Service..."
    until curl -f http://localhost:8000/health 2>/dev/null; do
        sleep 5
    done
    print_success "AI Service is ready"
    
    # Wait for Nginx
    print_status "Waiting for Nginx..."
    until curl -f http://localhost/health 2>/dev/null; do
        sleep 2
    done
    print_success "Nginx is ready"
}

# Initialize database
initialize_database() {
    print_status "Initializing database..."
    
    # Create database tables if needed
    docker-compose -f docker-compose.staging.yml exec postgres psql -U discourse -d discourse -c "
        CREATE TABLE IF NOT EXISTS community_statistics (
            id SERIAL PRIMARY KEY,
            total_members INTEGER DEFAULT 0,
            weekly_active_users INTEGER DEFAULT 0,
            peer_connections_initiated INTEGER DEFAULT 0,
            contributing_members_percentage DECIMAL(5,2) DEFAULT 0,
            members_by_level JSONB DEFAULT '{}',
            discussions_by_category JSONB DEFAULT '{}',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    " 2>/dev/null || true
    
    print_success "Database initialized"
}

# Show service status
show_status() {
    print_status "Service Status:"
    docker-compose -f docker-compose.staging.yml ps
    
    echo ""
    print_status "Access URLs:"
    echo "  🤖 AI Service API: http://localhost:8000"
    echo "  📊 Grafana Dashboard: http://localhost:3001 (admin/secure_grafana_password_2024)"
    echo "  📈 Prometheus Metrics: http://localhost:9090"
    echo "  📧 Mailtrap (Email Testing): http://localhost:8025"
    echo "  🛡️ Nginx Health Check: http://localhost/health"
    echo ""
    print_status "Database Access:"
    echo "  💾 PostgreSQL: localhost:5432 (discourse/discourse_password)"
    echo "  ⚡ Redis: localhost:6379"
    echo ""
    print_warning "Remember to update env.staging with your actual API keys and credentials!"
}

# Main execution
main() {
    echo "=========================================="
    echo "Circle of Peers Staging Environment Setup"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    load_environment
    setup_ssl
    start_services
    wait_for_services
    initialize_database
    show_status
    
    echo ""
    print_success "🎉 Staging environment is ready!"
    echo ""
    print_status "Next steps:"
    echo "  1. Update env.staging with your actual API keys"
    echo "  2. Test the AI service endpoints"
    echo "  3. Set up monitoring dashboards"
    echo "  4. Configure your domain to point to this server"
    echo "  5. Test all features and integrations"
    echo ""
    print_status "For Discourse setup, you'll need to:"
    echo "  1. Install Discourse separately or use a different approach"
    echo "  2. Configure it to use the PostgreSQL and Redis services"
    echo "  3. Install the custom plugins"
    echo ""
}

# Run main function
main "$@" 