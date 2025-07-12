# 🚀 Circle of Peers - Render Deployment

Quick deployment guide for the Circle of Peers platform using Render and GitHub.

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
OPENAI_API_KEY=your_openai_api_key
DISCOURSE_API_KEY=your_discourse_api_key
SMTP_HOST=smtp.circleofpeers.net
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
DISCOURSE_HOSTNAME=circleofpeers.net
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

## 🏗️ Architecture

```
GitHub Repository
       ↓
   Render Services
       ↓
┌─────────────────┐
│   Discourse     │ ← Main forum (circleofpeers.net)
├─────────────────┤
│   AI Service    │ ← Content moderation
├─────────────────┤
│ Landing Page    │ ← Marketing site
├─────────────────┤
│   PostgreSQL    │ ← Database
├─────────────────┤
│     Redis       │ ← Cache
└─────────────────┘
```

## 🔧 Services

### Main Services
- **Discourse**: Forum platform with custom plugins
- **AI Service**: Content moderation and peer responses
- **Landing Page**: Marketing and community statistics

### Infrastructure
- **PostgreSQL**: Primary database
- **Redis**: Caching and session storage
- **SSL/TLS**: Automatic HTTPS certificates
- **Monitoring**: Built-in logs and metrics

## 📊 Monitoring

### Access Points
- **Main App**: `https://circleofpeers.net`
- **AI Service**: `https://ai.circleofpeers.net`
- **Landing Page**: `https://landing.circleofpeers.net`
- **Render Dashboard**: [dashboard.render.com](https://dashboard.render.com)

### Health Checks
- Automatic health monitoring every 30 seconds
- Real-time logs in Render dashboard
- Performance metrics and alerts

## 🔄 Deployment Workflow

### Development
```bash
# Make changes
git add .
git commit -m "Add new feature"
git push origin main

# Render auto-deploys!
```

### Staging
```bash
# Create staging branch
git checkout -b staging
git push origin staging

# Test in staging environment
# Merge to main when ready
```

## 🛠️ Customization

### Environment Variables
Configure in Render Dashboard → Environment:
- `OPENAI_API_KEY`: Your OpenAI API key
- `DISCOURSE_API_KEY`: Discourse API key
- `SMTP_*`: Email configuration
- `DISCOURSE_HOSTNAME`: Your domain

### Custom Domain
1. Add domain in Render Dashboard
2. Update DNS records
3. SSL certificate auto-generated

### Scaling
- Enable auto-scaling in service settings
- Configure instance sizes as needed
- Monitor usage in dashboard

## 📋 Files Structure

```
circle-of-peers/
├── render.yaml              # Render configuration
├── Dockerfile.discourse     # Discourse container
├── Dockerfile.landing       # Landing page container
├── ai_service/              # AI service
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── plugins/                 # Custom plugins
│   ├── landing-page/
│   ├── peer-id-assignment/
│   ├── session-management/
│   ├── ai-moderation/
│   ├── terms-acknowledgment/
│   └── stripe-billing/
├── .github/workflows/       # CI/CD
│   └── deploy.yml
└── docs/                    # Documentation
    ├── RENDER_DEPLOYMENT.md
    └── README_RENDER.md
```

## 🚨 Troubleshooting

### Common Issues

**Service won't start?**
- Check logs in Render dashboard
- Verify environment variables
- Check database connections

**Database issues?**
- Verify `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- Check database logs in Render dashboard

**Plugin problems?**
- Check Discourse logs
- Verify plugin files are copied
- Ensure proper permissions

### Debug Commands
```bash
# Check service health
curl https://your-service.onrender.com/health

# View logs
# Render Dashboard → Service → Logs

# Test database
# Use Render's built-in database tools
```

## 💰 Cost Optimization

### Free Tier
- Start with free tier for testing
- PostgreSQL: 90 days free
- Redis: 30 days free
- Web services: Free tier available

### Scaling Up
- Upgrade only when needed
- Monitor usage in dashboard
- Use appropriate instance sizes

## 🔒 Security

### Best Practices
- Never commit secrets to GitHub
- Use Render's environment variables
- Enable SSL/TLS for all services
- Regular security updates

### Environment Variables
- Store sensitive data in Render dashboard
- Rotate keys regularly
- Use different keys for staging/production

## 📞 Support

### Render Support
- [Documentation](https://docs.render.com)
- [Community](https://community.render.com)
- [Status](https://status.render.com)

### GitHub Integration
- [GitHub Actions](https://github.com/features/actions)
- [GitHub Pages](https://pages.github.com)
- [GitHub Issues](https://github.com/features/issues)

---

**🎉 Ready to deploy!**

Your Circle of Peers platform is configured for production deployment on Render with automatic deployments from GitHub.

**Next steps:**
1. Push code to GitHub
2. Connect to Render
3. Configure environment variables
4. Deploy and test!

For detailed instructions, see [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) 