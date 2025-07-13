# 🚀 Circle of Peers - Render Deployment

Quick deployment guide for the Circle of Peers platform using Render and GitHub Actions.

## ⚡ Quick Start (5 Minutes)

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "Initial Circle of Peers platform"
git branch -M main
git remote add origin https://github.com/yourusername/circle-of-peers.git
git push -u origin main
```

### 2. Connect to Render
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click "New +" → "Blueprint"
3. Connect GitHub account
4. Select your repository
5. Click "Connect"

### 3. Configure Environment Variables
In Render Dashboard → Environment tab, add:
```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4

# Discourse Configuration
DISCOURSE_API_KEY=your_discourse_api_key
DISCOURSE_HOSTNAME=www.circleofpeers.net
DISCOURSE_CDN_URL=https://cdn.www.circleofpeers.net

# Email Configuration
SMTP_HOST=smtp.www.circleofpeers.net
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
SMTP_PORT=587
SMTP_TLS=true

# Database Configuration
POSTGRES_HOST=your_postgres_host
POSTGRES_USER=your_postgres_user
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=discourse_production

# Redis Configuration
REDIS_URL=your_redis_url
REDIS_PASSWORD=your_redis_password

# Security
SECRET_KEY_BASE=your_secret_key_base
DISCOURSE_DEVELOPER_EMAILS=admin@www.circleofpeers.net

# AI Service Configuration
AI_SERVICE_URL=https://ai.www.circleofpeers.net
AI_SERVICE_API_KEY=your_ai_service_key

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_key
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

### 4. Deploy!
Render will automatically:
- ✅ Create all services from `render.yaml`
- ✅ Set up PostgreSQL and Redis databases
- ✅ Deploy Discourse with custom plugins
- ✅ Deploy AI service for content moderation
- ✅ Deploy landing page
- ✅ Configure SSL certificates
- ✅ Set up monitoring

## 🔧 Technical Requirements

### Prerequisites
- **Render Account** with API access and billing enabled
- **GitHub repository** with Actions enabled
- **Domain name** with DNS access (circleofpeers.net)
- **OpenAI API key** for AI moderation features
- **Stripe account** for billing integration
- **SMTP server** for email notifications

### System Requirements
- **Discourse**: 2GB RAM, 1 CPU core minimum
- **AI Service**: 1GB RAM, 1 CPU core minimum
- **PostgreSQL**: 1GB RAM, 1 CPU core minimum
- **Redis**: 512MB RAM minimum
- **Landing Page**: 512MB RAM, 1 CPU core minimum

## 🏗️ Architecture

```
GitHub Repository
       ↓
GitHub Actions CI/CD
       ↓
   Render Services
       ↓
┌─────────────────┐
│   Discourse     │ ← Main forum (circleofpeers.net)
│   (2GB RAM)     │   - Custom plugins
│   - PostgreSQL  │   - AI moderation
│   - Redis       │   - User management
├─────────────────┤
│   AI Service    │ ← Content moderation
│   (1GB RAM)     │   - OpenAI integration
│   - Python      │   - Flagging system
├─────────────────┤
│ Landing Page    │ ← Marketing site
│   (512MB RAM)   │   - Community stats
│   - Static      │   - Registration
├─────────────────┤
│   PostgreSQL    │ ← Database (1GB RAM)
│   - Discourse   │   - User data
│   - Plugins     │   - Content
├─────────────────┤
│     Redis       │ ← Cache (512MB RAM)
│   - Sessions    │   - Caching
│   - Queues      │   - Real-time
└─────────────────┘
```

## 🔄 Automated Deployment Workflow

### GitHub Actions Pipeline
The platform uses a comprehensive CI/CD pipeline:

```yaml
# .github/workflows/deploy.yml
1. Test & Security Scan
   ↓
2. Build Docker Images
   ↓
3. Push to Container Registry
   ↓
4. Deploy to Render (Staging/Production)
   ↓
5. Database Migrations
   ↓
6. Health Checks
   ↓
7. Notifications
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

## 🔧 Services

### Main Services
- **Discourse**: Forum platform with custom plugins
- **AI Service**: Content moderation and peer responses
- **Landing Page**: Marketing and community statistics

### Infrastructure
- **PostgreSQL**: Primary database with automatic backups
- **Redis**: Caching and session storage
- **SSL/TLS**: Automatic HTTPS certificates
- **Monitoring**: Built-in logs and metrics

### Custom Plugins
```bash
plugins/
├── ai-moderation/          # AI content flagging
├── ai-verification/        # User verification
├── session-management/      # Session tracking
├── stripe-billing/         # Payment processing
├── user-blocking/          # User management
├── terms-acknowledgment/   # Legal compliance
├── landing-page/           # Marketing site
└── peer-id-assignment/     # Anonymous IDs
```

## 📊 Monitoring & Health Checks

### Health Check Endpoints
- **Discourse**: `https://circleofpeers.net/health`
- **AI Service**: `https://ai.circleofpeers.net/health`
- **Landing Page**: `https://landing.circleofpeers.net/health`

### Monitoring Dashboard
- **Render Dashboard**: [dashboard.render.com](https://dashboard.render.com)
- **Service Logs**: Real-time log streaming
- **Performance Metrics**: CPU, memory, response times
- **Error Tracking**: Automatic error detection

### Alert Configuration
```yaml
# Render Alerts
- Service down for >5 minutes
- Memory usage >80%
- CPU usage >90%
- Response time >2 seconds
- Database connection failures
```

## 🔒 Security Configuration

### API Key Management
```bash
# Rotate keys monthly
OPENAI_API_KEY=sk-... # OpenAI API
STRIPE_SECRET_KEY=sk_... # Stripe payments
DISCOURSE_API_KEY=... # Discourse API
```

### Database Security
- **Encryption at rest**: PostgreSQL data encryption
- **Encryption in transit**: SSL/TLS for all connections
- **Access control**: IP whitelisting for database
- **Backup encryption**: Automated encrypted backups

### SSL/TLS Configuration
```bash
# Automatic certificate renewal
certbot renew --quiet

# HSTS headers
add_header Strict-Transport-Security "max-age=31536000" always;
```

### Access Control
- **Admin access**: IP-restricted admin panel
- **API rate limiting**: 1000 requests/minute
- **Session management**: 10-minute inactivity timeout
- **Two-factor authentication**: Required for all users

## 💾 Backup & Recovery

### Automated Backups
```bash
# Daily database backups
pg_dump discourse_production | gzip > backup_$(date +%Y%m%d).sql.gz

# Weekly full backups
tar -czf full_backup_$(date +%Y%m%d).tar.gz /var/discourse/

# Monthly archive backups
aws s3 cp backup_*.sql.gz s3://circleofpeers-backups/
```

### Recovery Procedures
```bash
# Database recovery
gunzip -c backup_20241201.sql.gz | psql discourse_production

# Full system recovery
tar -xzf full_backup_20241201.tar.gz -C /

# Plugin recovery
git clone https://github.com/yourusername/circle-of-peers-plugins.git
```

### Backup Verification
- **Daily**: Automated backup integrity checks
- **Weekly**: Test recovery procedures
- **Monthly**: Full disaster recovery drill

## 🚨 Troubleshooting

### Common Issues

**Service won't start?**
```bash
# Check logs
render logs --service discourse-service

# Verify environment variables
render env list --service discourse-service

# Check database connections
psql $DATABASE_URL -c "SELECT 1;"
```

**Database issues?**
```bash
# Check PostgreSQL status
render logs --service postgres-service

# Verify connection strings
echo $POSTGRES_HOST
echo $POSTGRES_USER
echo $POSTGRES_PASSWORD

# Test database connection
psql "postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST/$POSTGRES_DB"
```

**Plugin problems?**
```bash
# Check Discourse logs
render logs --service discourse-service

# Verify plugin installation
docker exec discourse-service ls -la /var/www/discourse/plugins/

# Test plugin functionality
curl -H "Api-Key: $DISCOURSE_API_KEY" \
     -H "Content-Type: application/json" \
     https://circleofpeers.net/admin/plugins
```

**AI Service issues?**
```bash
# Check AI service logs
render logs --service ai-service

# Test OpenAI connection
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
     https://api.openai.com/v1/models

# Verify API endpoints
curl https://ai.circleofpeers.net/health
```

### Debug Commands
```bash
# Check service health
curl -f https://circleofpeers.net/health || echo "Service down"

# View real-time logs
render logs --service discourse-service --follow

# Check resource usage
render ps --service discourse-service

# Test database connectivity
psql $DATABASE_URL -c "SELECT version();"
```

## 💰 Cost Optimization

### Resource Allocation
```yaml
# Staging Environment (Free tier)
Discourse: 512MB RAM, 0.5 CPU
AI Service: 256MB RAM, 0.25 CPU
PostgreSQL: 256MB RAM, 0.25 CPU
Redis: 128MB RAM, 0.1 CPU

# Production Environment
Discourse: 2GB RAM, 1 CPU ($25/month)
AI Service: 1GB RAM, 0.5 CPU ($15/month)
PostgreSQL: 1GB RAM, 1 CPU ($20/month)
Redis: 512MB RAM, 0.5 CPU ($10/month)
Total: ~$70/month
```

### Scaling Guidelines
- **Start with free tier** for development
- **Scale up gradually** based on usage
- **Monitor costs** in Render dashboard
- **Use appropriate instance sizes**

## 📋 Files Structure

```
circle-of-peers/
├── render.yaml                    # Render configuration
├── docker-compose.yml            # Local development
├── Dockerfile.discourse          # Discourse container
├── Dockerfile.landing            # Landing page container
├── .github/workflows/            # CI/CD pipeline
│   └── deploy.yml               # Deployment workflow
├── ai_service/                   # AI service
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
├── plugins/                      # Custom plugins
│   ├── landing-page/
│   ├── peer-id-assignment/
│   ├── session-management/
│   ├── ai-moderation/
│   ├── terms-acknowledgment/
│   ├── stripe-billing/
│   ├── user-blocking/
│   ├── user-privacy-settings/
│   ├── user-profile-enhancement/
│   ├── user-referral-rewards/
│   ├── helpdesk-integration/
│   ├── email-change-verification/
│   └── ai-verification/
├── nginx/                        # Web server config
│   ├── nginx.conf
│   └── ssl/
├── monitoring/                   # Monitoring setup
│   ├── grafana/
│   ├── prometheus.yml
│   └── dashboards/
├── backups/                      # Backup scripts
│   ├── postgres/
│   └── redis/
└── docs/                         # Documentation
    ├── RENDER_DEPLOYMENT.md
    ├── README_RENDER.md
    ├── GETTING_STARTED.md
    ├── DEVELOPMENT.md
    └── STAGING_SETUP.md
```

## 📞 Support & Maintenance

### Render Support
- [Documentation](https://docs.render.com)
- [Community](https://community.render.com)
- [Status](https://status.render.com)
- [API Reference](https://api.render.com)

### GitHub Integration
- [GitHub Actions](https://github.com/features/actions)
- [GitHub Pages](https://pages.github.com)
- [GitHub Issues](https://github.com/features/issues)
- [GitHub Security](https://github.com/security)

### Maintenance Schedule
```bash
# Daily
- Monitor service health
- Check backup status
- Review error logs

# Weekly
- Update dependencies
- Review performance metrics
- Test backup recovery

# Monthly
- Security updates
- Cost optimization review
- Full system audit
```

---

**🎉 Ready to deploy!**

Your Circle of Peers platform is configured for production deployment on Render with automated CI/CD pipeline, comprehensive monitoring, and security best practices.

**Next steps:**
1. Push code to GitHub
2. Configure GitHub secrets
3. Connect to Render
4. Set up environment variables
5. Deploy and test!

For detailed technical instructions, see [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) 