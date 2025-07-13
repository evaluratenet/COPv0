# Circle of Peers - Development Guide

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- OpenAI API key (for AI features)

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd circle-of-peers

# Copy environment file
cp env.example .env

# Edit .env with your actual values
# - Add your OpenAI API key
# - Configure other settings as needed
```

### 2. Start Development Environment

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f discourse
docker-compose logs -f ai_service
```

### 3. Access Services

- **Discourse**: http://localhost:3000
- **AI Service API**: http://localhost:8000
- **Mailtrap (Email Testing)**: http://localhost:8025
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 4. Email Configuration

**Production Email Addresses:**
- **📫 noreply@circleofpeers.net**: System notifications, 2FA codes, registration confirmations
- **👥 support@circleofpeers.net**: User support and helpdesk integration
- **🧾 verification@circleofpeers.net**: Reference verification during onboarding
- **🛡 moderation@circleofpeers.net**: AI flag notifications and user appeals
- **🧑‍💼 admin@circleofpeers.net**: Administrative communications
- **💰 billing@circleofpeers.net**: Stripe receipts and payment support

**Development Email Testing:**
- All emails routed to Mailtrap for testing
- Configure SPF, DKIM, and DMARC for production deliverability

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Our automated deployment pipeline includes comprehensive testing and deployment:

#### 1. Testing & Security Scan
```yaml
# .github/workflows/deploy.yml
- Python dependency installation
- Unit and integration tests with pytest
- Code linting with flake8 and black
- Security scanning with CodeQL
- Multi-language analysis (Python, JavaScript)
```

#### 2. Build & Push
```yaml
- Docker image building for Discourse and Landing page
- Container registry integration (GitHub Container Registry)
- Multi-stage caching for faster builds
- Image tagging with commit SHA and latest tags
```

#### 3. Deployment
```yaml
- Render API integration for staging/production
- Database migrations
- Health check verification
- Slack notifications
- Automatic rollback on failure
```

### Deployment Triggers

- **Staging**: Push to `staging` branch
- **Production**: Push to `main` branch
- **Pull Requests**: Run tests only

### Required GitHub Secrets

```yaml
RENDER_API_KEY: "your-render-api-key"
RENDER_STAGING_SERVICE_ID: "your-staging-service-id"
RENDER_PRODUCTION_SERVICE_ID: "your-production-service-id"
STAGING_URL: "https://staging.circleofpeers.net"
PRODUCTION_URL: "https://circleofpeers.net"
SLACK_WEBHOOK_URL: "your-slack-webhook-url"
```

### Local CI/CD Testing

```bash
# Test GitHub Actions locally
act -j test

# View workflow runs
# Go to GitHub → Actions tab

# Debug deployment issues
# Check Render dashboard for service logs
```

## 🏗️ Architecture Overview

### Services
- **Discourse**: Main forum platform with custom plugins
- **FastAPI AI Service**: Content moderation and peer AI responses
- **Stripe**: Payment processing and subscription management
- **PostgreSQL**: Primary database with custom billing tables
- **Redis**: Caching and session storage
- **Mailtrap**: Email testing in development

### Plugin Structure
```
plugins/
├── peer-id-assignment/     # Core identity system
├── session-management/     # Single session enforcement with inactivity monitoring
├── ai-moderation/          # Content moderation & flagging system
├── terms-acknowledgment/   # Terms and Conditions acceptance
└── stripe-billing/         # Subscription management with Stripe integration
```

## 🔧 Development Workflow

### Adding New Plugins

1. Create plugin directory structure:
```bash
mkdir plugins/my-new-plugin
cd plugins/my-new-plugin
```

2. Create required files:
- `plugin.yml` - Plugin metadata
- `plugin.rb` - Main plugin logic
- `models/` - Database models
- `controllers/` - Admin controllers
- `jobs/` - Background jobs
- `assets/` - JavaScript/CSS

3. Register plugin in Discourse:
```ruby
# In plugin.rb
enabled_site_setting :my_plugin_enabled
```

### Testing AI Service

```bash
# Test moderation endpoint
curl -X POST http://localhost:8000/moderate \
  -H "Content-Type: application/json" \
  -d '{
    "post_id": 1,
    "user_id": 1,
    "peer_id": "Peer #001",
    "content": "Hey everyone, I have a great business opportunity..."
  }'

# Test user flagging endpoint
curl -X POST http://localhost:8000/flag \
  -H "Content-Type: application/json" \
  -d '{
    "post_id": 1,
    "user_id": 1,
    "peer_id": "Peer #001",
    "content": "Test content",
    "violation_type": "solicitation",
    "reason": "Contains promotional content"
  }'

# Test webhook endpoint
curl -X POST http://localhost:8000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "post_created",
    "post_id": 1,
    "user_id": 1,
    "peer_id": "Peer #001",
    "content": "Test post content"
  }'

# Test health check
curl http://localhost:8000/health

# Test billing endpoints
curl -X GET http://localhost:3000/billing/subscription \
  -H "Cookie: _t=session_token"

curl -X POST http://localhost:3000/billing/create_subscription \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: token" \
  -d '{"plan_type": "monthly", "stripe_token": "tok_visa"}'
```

### Database Migrations

```bash
# Run migrations in Discourse container
docker-compose exec discourse rails db:migrate

# Create new migration
docker-compose exec discourse rails generate migration AddNewTable
```

## 🧪 Testing

### Test Data Setup

1. Create test users in Discourse admin
2. Assign peer IDs via admin panel
3. Create test posts with various violation types
4. Test AI moderation responses

### Violation Test Cases

```javascript
// Test posts for AI moderation
const testPosts = [
  {
    content: "Hey everyone, I have a great business opportunity to share...",
    expected: "solicitation",
    severity: 3
  },
  {
    content: "My email is john.doe@company.com and phone is 555-1234",
    expected: "pii",
    severity: 4
  },
  {
    content: "You're all idiots and this discussion is worthless",
    expected: "harassment",
    severity: 5
  },
  {
    content: "I work at Google and we're about to launch a new product...",
    expected: "confidential",
    severity: 4
  },
  {
    content: "What's everyone's favorite pizza topping?",
    expected: "off_topic",
    severity: 2
  }
];
```

### Automated Testing

```bash
# Run all tests
docker-compose exec ai_service python -m pytest

# Run specific test file
docker-compose exec ai_service python -m pytest tests/test_moderation.py

# Run with coverage
docker-compose exec ai_service python -m pytest --cov=app tests/
```

## 🚀 Deployment

### Staging Deployment

```bash
# Create staging branch
git checkout -b staging
git push origin staging

# GitHub Actions will automatically:
# 1. Run tests
# 2. Build Docker images
# 3. Deploy to staging environment
# 4. Run health checks
# 5. Send notifications
```

### Production Deployment

```bash
# Merge to main branch
git checkout main
git merge staging
git push origin main

# GitHub Actions will automatically:
# 1. Run comprehensive tests
# 2. Build production images
# 3. Deploy to production
# 4. Run database migrations
# 5. Verify health checks
# 6. Send Slack notifications
```

### Deployment Monitoring

```bash
# Check deployment status
curl -H "Authorization: Bearer $RENDER_API_KEY" \
     https://api.render.com/v1/services/$SERVICE_ID/deploys

# View service logs
# Render Dashboard → Service → Logs

# Test health endpoints
curl https://your-service.onrender.com/health
```

## 🔍 Debugging

### CI/CD Issues

```bash
# Check GitHub Actions logs
# Go to GitHub → Actions → Recent workflow runs

# Verify secrets are set
# Go to GitHub → Settings → Secrets and variables → Actions

# Test Render API connection
curl -H "Authorization: Bearer $RENDER_API_KEY" \
     https://api.render.com/v1/services
```

### Local Development Issues

```bash
# Check service logs
docker-compose logs -f service_name

# Restart specific service
docker-compose restart service_name

# Rebuild containers
docker-compose build --no-cache

# Reset database
docker-compose exec discourse rails db:reset
```

## 📚 Additional Resources

- **Deployment Guide**: [README_RENDER.md](README_RENDER.md)
- **Getting Started**: [GETTING_STARTED.md](GETTING_STARTED.md)
- **Staging Setup**: [STAGING_SETUP.md](STAGING_SETUP.md)
- **System Design**: [System Design Document.md](System%20Design%20Document.md) 

## Documentation

- **User Document.md**: Complete user experience guide
- **FLAGGING_SYSTEM.md**: Detailed flagging system documentation
- **COMMUNITY_GUIDELINES.md**: Behavioral expectations, privacy, moderation, and consequences
- **DEVELOPMENT.md**: Development setup and testing guide

## Onboarding

- Users must agree to the [Community Guidelines](/community-guidelines) at signup. The guidelines are linked from the signup page and onboarding flow. 