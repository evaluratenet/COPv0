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

// Test billing scenarios
const billingTests = [
  {
    scenario: "New user registration",
    expected: "30-day trial subscription created"
  },
  {
    scenario: "Trial expiration",
    expected: "Payment attempt or payment method request"
  },
  {
    scenario: "Monthly subscription",
    expected: "$50/month billing via Stripe"
  },
  {
    scenario: "Annual subscription",
    expected: "$500/year billing via Stripe"
  },
  {
    scenario: "Payment failure",
    expected: "Retry logic with notifications"
  }
];
```

## 📊 Monitoring & Debugging

### View Logs
```bash
# All services
docker-compose logs

# Specific service
docker-compose logs discourse
docker-compose logs ai_service

# Follow logs
docker-compose logs -f
```

### Database Access
```bash
# PostgreSQL
docker-compose exec postgres psql -U discourse -d discourse

# Redis
docker-compose exec redis redis-cli
```

### Email Testing
```bash
# View email logs in Mailtrap
open http://localhost:8025

# Test email sending
docker-compose exec discourse rails console
# In console: ActionMailer::Base.delivery_method = :test
```

### Discourse Console
```bash
docker-compose exec discourse rails console
```

## 🔐 Security Considerations

### Development vs Production

- **Development**: Uses Mailtrap for email testing
- **Production**: Configure real SMTP server
- **Development**: Basic security settings
- **Production**: Full SSL, security headers, etc.

### API Keys

- Never commit `.env` file
- Use environment variables for all secrets
- Rotate API keys regularly
- Monitor API usage

## 🚀 Deployment Preparation

### Production Checklist

- [ ] Configure production SMTP with all email addresses
- [ ] Set up SPF, DKIM, and DMARC for email deliverability
- [ ] Configure helpdesk integration for support@circleofpeers.net
- [ ] Set up SSL certificates
- [ ] Configure backup strategy
- [ ] Set production environment variables
- [ ] Test all plugins in staging
- [ ] Configure monitoring and logging
- [ ] Set up CI/CD pipeline

### Environment Variables

```bash
# Production .env
NODE_ENV=production
RAILS_ENV=production
DISCOURSE_HOSTNAME=circleofpeers.net
OPENAI_API_KEY=your_production_key
DISCOURSE_API_KEY=your_production_key

# Email Configuration
SMTP_ADDRESS=smtp.circleofpeers.net
SMTP_PORT=587
SMTP_USERNAME=noreply@circleofpeers.net
SMTP_PASSWORD=your_smtp_password

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

## 📝 Plugin Development Tips

### Best Practices

1. **Use Discourse hooks** instead of monkey-patching
2. **Test thoroughly** before deploying
3. **Follow Discourse conventions** for naming and structure
4. **Use background jobs** for heavy operations
5. **Cache expensive operations** with Redis
6. **Log important events** for debugging

### Common Patterns

```ruby
# Hook into user events
on(:user_approved) do |user|
  # Your logic here
end

# Add to serializers
add_to_serializer(:user, :custom_field) do
  object.custom_fields['your_field']
end

# Create background jobs
module Jobs
  class YourJob < ::Jobs::Base
    def execute(args)
      # Job logic
    end
  end
end
```

## 🆘 Troubleshooting

### Common Issues

1. **Discourse won't start**: Check PostgreSQL connection
2. **AI service errors**: Verify OpenAI API key
3. **Plugin not loading**: Check plugin.yml syntax
4. **Database connection issues**: Verify credentials in .env

### Debug Commands

```bash
# Restart specific service
docker-compose restart discourse

# Rebuild containers
docker-compose build --no-cache

# Reset database
docker-compose down -v
docker-compose up -d
```

## 📚 Resources

- [Discourse Plugin Development](https://docs.discourse.org/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [OpenAI API Documentation](https://platform.openai.com/docs/) 

## Documentation

- **User Document.md**: Complete user experience guide
- **FLAGGING_SYSTEM.md**: Detailed flagging system documentation
- **COMMUNITY_GUIDELINES.md**: Behavioral expectations, privacy, moderation, and consequences
- **DEVELOPMENT.md**: Development setup and testing guide

## Onboarding

- Users must agree to the [Community Guidelines](/community-guidelines) at signup. The guidelines are linked from the signup page and onboarding flow. 