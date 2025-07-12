# Circle of Peers Staging Environment Setup

This guide will help you set up and use the production-like staging environment for the Circle of Peers platform.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git
- OpenAI API key
- Domain name (optional, for full production-like testing)

### 1. Environment Setup

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd circle-of-peers

# Copy and configure environment file
cp env.example env.staging

# Edit env.staging with your actual values:
# - Add your OpenAI API key
# - Configure Discourse API key
# - Set up email credentials
# - Configure S3 backup settings (optional)
```

### 2. Start Staging Environment

```bash
# Run the staging startup script
./start-staging.sh
```

This script will:
- ✅ Check prerequisites
- ✅ Load environment variables
- ✅ Create SSL certificates
- ✅ Start all services
- ✅ Wait for services to be ready
- ✅ Run database migrations
- ✅ Initialize plugins
- ✅ Create admin user
- ✅ Show access information

### 3. Access Your Staging Environment

After the startup script completes, you can access:

- **🌐 Main Application**: https://staging.circleofpeers.net
- **📊 Grafana Dashboard**: http://localhost:3001
- **📈 Prometheus Metrics**: http://localhost:9090
- **📧 Mailtrap (Email Testing)**: http://localhost:8025

**Admin Credentials:**
- Email: `admin@circleofpeers.net`
- Password: `admin123456`

## 🏗️ Architecture Overview

### Services Running

1. **Discourse** (Port 3000)
   - Main forum platform
   - Custom plugins enabled
   - Production-like configuration

2. **AI Service** (Port 8000)
   - Content moderation
   - Peer AI responses
   - Webhook processing

3. **PostgreSQL** (Port 5432)
   - Primary database
   - Custom billing tables
   - Automated backups

4. **Redis** (Port 6379)
   - Caching layer
   - Session storage
   - Background job queue

5. **Nginx** (Port 80/443)
   - Reverse proxy
   - SSL termination
   - Load balancing
   - Rate limiting

6. **Monitoring Stack**
   - Prometheus (Port 9090)
   - Grafana (Port 3001)
   - Health checks

## 🔧 Development Workflow

### Working with Plugins

```bash
# Access Discourse container
docker-compose -f docker-compose.staging.yml exec discourse bash

# View plugin logs
docker-compose -f docker-compose.staging.yml logs discourse

# Restart Discourse after plugin changes
docker-compose -f docker-compose.staging.yml restart discourse
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
    "content": "Test content for moderation"
  }'

# Test health check
curl http://localhost:8000/health
```

### Database Operations

```bash
# Access PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres psql -U discourse -d discourse

# Run migrations
docker-compose -f docker-compose.staging.yml exec discourse rails db:migrate

# Create backup
docker-compose -f docker-compose.staging.yml exec postgres pg_dump -U discourse discourse > backup.sql
```

## 📊 Monitoring & Observability

### Grafana Dashboards

Access Grafana at `http://localhost:3001` with:
- Username: `admin`
- Password: `secure_grafana_password_2024`

**Available Dashboards:**
- System Overview
- Discourse Performance
- AI Service Metrics
- Database Performance
- User Activity

### Prometheus Metrics

Access Prometheus at `http://localhost:9090` to view:
- Service health
- Performance metrics
- Custom business metrics
- Alert rules

### Health Checks

```bash
# Check all services
curl http://localhost/health

# Check individual services
curl http://localhost:3000/health  # Discourse
curl http://localhost:8000/health  # AI Service
```

## 🧪 Testing Scenarios

### User Registration Flow

1. Visit https://staging.circleofpeers.net
2. Click "Sign Up"
3. Complete registration form
4. Verify email (check Mailtrap)
5. Complete onboarding process
6. Test peer ID assignment

### Content Moderation Testing

```javascript
// Test posts for AI moderation
const testPosts = [
  {
    content: "Hey everyone, I have a great business opportunity...",
    expected: "solicitation"
  },
  {
    content: "My email is john@company.com and phone is 555-1234",
    expected: "pii"
  },
  {
    content: "You're all idiots and this discussion is worthless",
    expected: "harassment"
  }
];
```

### Billing Integration Testing

```bash
# Test subscription creation
curl -X POST http://localhost:3000/billing/create_subscription \
  -H "Content-Type: application/json" \
  -H "X-CSRF-Token: token" \
  -d '{"plan_type": "monthly", "stripe_token": "tok_visa"}'

# Test subscription status
curl -X GET http://localhost:3000/billing/subscription \
  -H "Cookie: _t=session_token"
```

## 🔒 Security Configuration

### SSL/TLS Setup

The staging environment includes:
- Self-signed certificates for testing
- Production-ready SSL configuration
- Security headers
- Rate limiting

### Production SSL Setup

For production deployment:

```bash
# Generate Let's Encrypt certificates
certbot certonly --webroot -w /var/www/html \
  -d staging.circleofpeers.net \
  --email admin@circleofpeers.net

# Copy certificates
cp /etc/letsencrypt/live/staging.circleofpeers.net/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/staging.circleofpeers.net/privkey.pem ssl/key.pem
```

## 📈 Performance Optimization

### Database Optimization

```sql
-- Check slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Analyze table performance
ANALYZE users;
ANALYZE posts;
ANALYZE topics;
```

### Redis Optimization

```bash
# Monitor Redis performance
docker-compose -f docker-compose.staging.yml exec redis redis-cli info memory

# Check cache hit rates
docker-compose -f docker-compose.staging.yml exec redis redis-cli info stats
```

### Application Performance

```bash
# Monitor Discourse performance
docker-compose -f docker-compose.staging.yml exec discourse rails console
# Then run: Discourse.cache.stats

# Check background job queue
docker-compose -f docker-compose.staging.yml exec discourse rails console
# Then run: Sidekiq::Stats.new
```

## 🚨 Troubleshooting

### Common Issues

#### Services Not Starting

```bash
# Check service logs
docker-compose -f docker-compose.staging.yml logs

# Check specific service
docker-compose -f docker-compose.staging.yml logs discourse

# Restart services
docker-compose -f docker-compose.staging.yml restart
```

#### Database Connection Issues

```bash
# Check PostgreSQL status
docker-compose -f docker-compose.staging.yml exec postgres pg_isready -U discourse

# Reset database (if needed)
docker-compose -f docker-compose.staging.yml exec discourse rails db:reset
```

#### Plugin Issues

```bash
# Check plugin status
docker-compose -f docker-compose.staging.yml exec discourse rails console
# Then run: Plugin.all.map { |p| [p.name, p.enabled?] }

# Enable specific plugin
docker-compose -f docker-compose.staging.yml exec discourse rails console
# Then run: Plugin.find_by(name: 'plugin_name').update(enabled: true)
```

### Debug Commands

```bash
# Check container status
docker-compose -f docker-compose.staging.yml ps

# View resource usage
docker stats

# Access container shell
docker-compose -f docker-compose.staging.yml exec discourse bash

# Check disk space
docker system df
```

## 🔄 Maintenance

### Regular Tasks

#### Daily
- Check service health
- Monitor error logs
- Verify backup completion

#### Weekly
- Review performance metrics
- Update dependencies
- Test backup restoration

#### Monthly
- Security updates
- Performance optimization
- Capacity planning

### Backup Strategy

```bash
# Manual backup
./backup-staging.sh

# Automated backups (configured in docker-compose)
# - PostgreSQL: Daily
# - Redis: Daily
# - File system: Weekly
```

## 📋 Deployment Checklist

Before deploying to production:

- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Security scan completed
- [ ] SSL certificates configured
- [ ] Monitoring alerts set up
- [ ] Backup strategy verified
- [ ] Disaster recovery plan tested
- [ ] Documentation updated

## 🎯 Next Steps

### Immediate Actions

1. **Configure Environment**
   - Update `env.staging` with real API keys
   - Set up domain DNS
   - Configure SSL certificates

2. **Test Core Features**
   - User registration and onboarding
   - Content moderation
   - Billing integration
   - Plugin functionality

3. **Set Up Monitoring**
   - Configure Grafana dashboards
   - Set up alerting rules
   - Monitor performance metrics

### Future Enhancements

1. **Advanced Testing**
   - Load testing
   - Security testing
   - Integration testing

2. **CI/CD Pipeline**
   - Automated testing
   - Deployment automation
   - Rollback procedures

3. **Production Readiness**
   - High availability setup
   - Disaster recovery
   - Performance optimization

## 📞 Support

For issues and questions:

1. **Check Logs**: Use the troubleshooting commands above
2. **Review Documentation**: Check the main README and technical docs
3. **Community Support**: Use Discourse community forums
4. **Development Team**: Contact for technical issues

---

**Happy Development! 🚀**

The staging environment is now ready for testing and development. Remember to keep your environment variables secure and never commit sensitive information to version control. 