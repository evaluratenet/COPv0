# 🚀 Getting Started - Circle of Peers Development

Welcome to the Circle of Peers development environment! This guide will help you get up and running quickly.

## What We've Built

### ✅ Production-Like Staging Environment

We've created a comprehensive staging environment that mirrors production, including:

- **🌐 Discourse Platform** with custom plugins
- **🤖 AI Service** for content moderation
- **💾 PostgreSQL Database** with custom billing tables
- **⚡ Redis Cache** for performance
- **🛡️ Nginx Reverse Proxy** with SSL/TLS
- **📊 Monitoring Stack** (Prometheus + Grafana)
- **📧 Email Testing** with Mailtrap
- **🔄 Automated Backups** to S3

### ✅ Custom Plugins Implemented

1. **Landing Page Plugin** - Dynamic landing page with community statistics
2. **Peer ID Assignment** - Unique identity system for members
3. **Session Management** - Single session enforcement
4. **AI Moderation** - Content moderation and flagging
5. **Terms Acknowledgment** - Legal compliance
6. **Stripe Billing** - Subscription management

## 🚀 Quick Start (3 Steps)

### Step 1: Configure Environment

```bash
# Copy environment template
cp env.example env.staging

# Edit env.staging with your actual values:
# - OpenAI API key
# - Discourse API key  
# - Email credentials
# - S3 backup settings (optional)
```

### Step 2: Start the Environment

```bash
# Run the automated setup script
./start-staging.sh
```

This script will automatically:
- ✅ Check prerequisites
- ✅ Create SSL certificates
- ✅ Start all services
- ✅ Run database migrations
- ✅ Initialize plugins
- ✅ Create admin user
- ✅ Show access information

### Step 3: Access Your Environment

After the script completes, access:

- **🌐 Main App**: https://staging.circleofpeers.net
- **📊 Grafana**: http://localhost:3001 (admin/secure_grafana_password_2024)
- **📈 Prometheus**: http://localhost:9090
- **📧 Email Testing**: http://localhost:8025

**Admin Login:**
- Email: `admin@circleofpeers.net`
- Password: `admin123456`

## 🧪 Testing Your Setup

### Test Core Features

1. **User Registration**
   - Visit the landing page
   - Sign up as a new user
   - Complete onboarding process
   - Verify peer ID assignment

2. **Content Moderation**
   ```bash
   # Test AI moderation
   curl -X POST http://localhost:8000/moderate \
     -H "Content-Type: application/json" \
     -d '{
       "post_id": 1,
       "user_id": 1,
       "peer_id": "Peer #001",
       "content": "Test content for moderation"
     }'
   ```

3. **Billing Integration**
   ```bash
   # Test subscription creation
   curl -X POST http://localhost:3000/billing/create_subscription \
     -H "Content-Type: application/json" \
     -d '{"plan_type": "monthly", "stripe_token": "tok_visa"}'
   ```

### Test Plugins

1. **Landing Page**: Visit `/landing` to see dynamic community statistics
2. **Peer IDs**: Check admin panel for peer ID assignment
3. **Session Management**: Test single session enforcement
4. **AI Moderation**: Create posts to test content moderation
5. **Terms**: Verify terms acceptance during registration

## 🔧 Development Workflow

### Working with Plugins

```bash
# Access Discourse container
docker-compose -f docker-compose.staging.yml exec discourse bash

# View logs
docker-compose -f docker-compose.staging.yml logs discourse

# Restart after changes
docker-compose -f docker-compose.staging.yml restart discourse
```

### Database Operations

```bash
# Access PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres psql -U discourse -d discourse

# Run migrations
docker-compose -f docker-compose.staging.yml exec discourse rails db:migrate
```

### Monitoring

```bash
# Check service health
curl http://localhost/health

# View service status
docker-compose -f docker-compose.staging.yml ps
```

## 📊 What's Included

### Core Services
- **Discourse** (Port 3000) - Main forum platform
- **AI Service** (Port 8000) - Content moderation
- **PostgreSQL** (Port 5432) - Database
- **Redis** (Port 6379) - Cache
- **Nginx** (Port 80/443) - Reverse proxy
- **Prometheus** (Port 9090) - Metrics
- **Grafana** (Port 3001) - Dashboards

### Custom Plugins
- **Landing Page** - Dynamic landing with statistics
- **Peer ID Assignment** - Unique member identities
- **Session Management** - Single session enforcement
- **AI Moderation** - Content moderation system
- **Terms Acknowledgment** - Legal compliance
- **Stripe Billing** - Subscription management

### Production Features
- **SSL/TLS** - Secure connections
- **Rate Limiting** - API protection
- **Monitoring** - Performance tracking
- **Backups** - Automated data protection
- **Health Checks** - Service monitoring
- **Load Balancing** - High availability

## 🚨 Troubleshooting

### Common Issues

**Services not starting?**
```bash
# Check logs
docker-compose -f docker-compose.staging.yml logs

# Restart services
docker-compose -f docker-compose.staging.yml restart
```

**Database connection issues?**
```bash
# Check PostgreSQL
docker-compose -f docker-compose.staging.yml exec postgres pg_isready -U discourse

# Reset database (if needed)
docker-compose -f docker-compose.staging.yml exec discourse rails db:reset
```

**Plugin not working?**
```bash
# Check plugin status
docker-compose -f docker-compose.staging.yml exec discourse rails console
# Then run: Plugin.all.map { |p| [p.name, p.enabled?] }
```

## 📚 Documentation

- **📖 Main README**: Complete project overview
- **🔧 DEVELOPMENT.md**: Development workflow
- **🏗️ STAGING_SETUP.md**: Detailed staging guide
- **📋 TECHNICAL.md**: Technical implementation details
- **🚀 QUICK_START.md**: Plugin quick start guide

## 🎯 Next Steps

### Immediate Actions
1. **Configure Environment** - Update `env.staging` with real API keys
2. **Test Features** - Run through all core functionality
3. **Set Up Monitoring** - Configure alerts and dashboards

### Development Priorities
1. **Plugin Development** - Enhance existing plugins
2. **Testing** - Comprehensive test coverage
3. **Performance** - Optimize for production load
4. **Security** - Security audit and hardening

### Production Deployment
1. **Environment Setup** - Production server configuration
2. **SSL Certificates** - Let's Encrypt setup
3. **Monitoring** - Production monitoring setup
4. **Backup Strategy** - Automated backup verification

## 🆘 Need Help?

1. **Check Documentation** - Review the guides above
2. **View Logs** - Use troubleshooting commands
3. **Community Support** - Use Discourse forums
4. **Development Team** - Contact for technical issues

---

**🎉 You're all set!** 

Your production-like staging environment is ready for development and testing. The platform includes all the core features needed for the Circle of Peers community, with robust monitoring, security, and scalability built in.

Happy coding! 🚀 