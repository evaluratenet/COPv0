# Quick Start Guide - Landing Page Plugin

This guide will help you get the Circle of Peers Landing Page Plugin up and running quickly.

## Prerequisites

- Discourse installation (version 2.8+)
- Admin access to your Discourse instance
- Basic familiarity with Discourse administration

## Installation

### Step 1: Install the Plugin

1. Navigate to your Discourse installation directory
2. Copy the plugin to the plugins folder:
   ```bash
   cp -r landing-page /path/to/discourse/plugins/
   ```

### Step 2: Enable the Plugin

1. Log in to your Discourse admin panel
2. Go to **Admin → Plugins**
3. Find "Landing Page" in the list
4. Click **Enable**

### Step 3: Verify Installation

1. Visit your site URL + `/landing` (e.g., `https://yoursite.com/landing`)
2. You should see the landing page with community statistics
3. Check that the statistics are displaying correctly

## Configuration

### Basic Settings

1. Go to **Admin → Plugins → Landing Page**
2. Configure the following settings:

#### Statistics Refresh Interval
- **Default**: 1 hour
- **Recommended**: 1 hour for most sites
- **High-traffic sites**: Consider 30 minutes

#### Auto-refresh for Admins
- **Enabled**: Statistics automatically refresh for admin users
- **Disabled**: Manual refresh only

#### Display Settings
- Choose which statistics to display
- Configure number formatting
- Set up custom branding

### Advanced Configuration

#### Custom Branding
1. Edit `stylesheets/landing-page.scss`
2. Update colors and fonts to match your brand
3. Recompile assets: `rake assets:precompile`

#### Content Customization
1. Edit `views/landing/index.html.erb` for main content
2. Modify additional pages as needed
3. Update statistics calculation in `models/community_statistics.rb`

## Testing

### Quick Test Checklist

- [ ] Landing page loads at `/landing`
- [ ] Statistics display correctly
- [ ] About, Features, Pricing, Contact pages work
- [ ] Mobile responsiveness looks good
- [ ] Admin auto-refresh works (if enabled)

### Performance Testing

1. **Load Testing**
   - Test with multiple concurrent users
   - Monitor page load times
   - Check background job performance

2. **Statistics Accuracy**
   - Verify member counts match admin panel
   - Check activity statistics accuracy
   - Confirm cache updates properly

## Troubleshooting

### Common Issues

#### Landing Page Not Loading
```
Error: Page not found
```
**Solution**: Verify plugin is enabled and routes are registered

#### Statistics Not Updating
```
Statistics showing old data
```
**Solution**: 
1. Check background job logs
2. Clear cache: `Rails.cache.clear`
3. Restart background job workers

#### Performance Issues
```
Slow page loads
```
**Solution**:
1. Increase statistics refresh interval
2. Check database query performance
3. Monitor server resources

### Debug Commands

```bash
# Check plugin status
rails console
Plugin.find_by(name: 'landing-page').enabled?

# Clear cache
rails console
Rails.cache.clear

# Check background jobs
rake jobs:work

# View logs
tail -f log/production.log
```

## Monitoring

### Key Metrics to Watch

1. **Page Performance**
   - Landing page load time
   - Statistics calculation time
   - Background job execution time

2. **User Engagement**
   - Landing page visits
   - Sign-up conversions
   - User activity after landing page visit

3. **System Health**
   - Background job success rate
   - Cache hit/miss ratios
   - Database query performance

### Setting Up Alerts

1. **Failed Background Jobs**
   - Monitor job execution logs
   - Set up email alerts for failures

2. **High Load Times**
   - Monitor page load times
   - Alert if load time exceeds threshold

3. **Cache Issues**
   - Monitor cache hit rates
   - Alert on cache misses

## Maintenance

### Regular Tasks

#### Weekly
- Review landing page analytics
- Check statistics accuracy
- Monitor user feedback

#### Monthly
- Update content as needed
- Review performance metrics
- Check for plugin updates

#### Quarterly
- Full performance review
- Content refresh
- User experience assessment

### Backup and Recovery

1. **Backup Configuration**
   ```bash
   # Backup plugin configuration
   cp -r plugins/landing-page /backup/
   ```

2. **Restore Process**
   ```bash
   # Restore from backup
   cp -r /backup/landing-page plugins/
   rake assets:precompile
   sudo systemctl restart discourse
   ```

## Support

### Getting Help

1. **Check Documentation**
   - Review README.md for user guide
   - Check TECHNICAL.md for developer info
   - Consult this quick start guide

2. **Community Support**
   - Discourse community forums
   - GitHub issues (if applicable)
   - Developer documentation

3. **Emergency Contacts**
   - System administrator
   - Development team
   - Hosting provider

### Reporting Issues

When reporting issues, include:
- Discourse version
- Plugin version
- Error messages
- Steps to reproduce
- System logs

## Next Steps

### Immediate Actions

1. **Customize Content**
   - Update landing page copy
   - Add your branding
   - Configure statistics display

2. **Test Thoroughly**
   - Test all pages
   - Verify mobile experience
   - Check performance

3. **Monitor Performance**
   - Set up monitoring
   - Track user engagement
   - Monitor system health

### Future Enhancements

1. **Advanced Features**
   - A/B testing
   - Conversion tracking
   - Advanced analytics

2. **Integration**
   - Email marketing tools
   - CRM integration
   - Social media feeds

3. **Customization**
   - Theme customization
   - Content management
   - Multi-language support

## Success Metrics

### Key Performance Indicators

1. **Conversion Rate**
   - Landing page to sign-up conversion
   - Target: 5-10% (industry standard)

2. **Engagement**
   - Time on landing page
   - Click-through rates
   - User interaction

3. **Technical Performance**
   - Page load time < 3 seconds
   - 99.9% uptime
   - Background job success rate > 95%

### Regular Reviews

- **Weekly**: Check basic metrics
- **Monthly**: Full performance review
- **Quarterly**: Strategy assessment

## Conclusion

The Circle of Peers Landing Page Plugin provides a powerful foundation for engaging new users and showcasing your community. With proper setup and monitoring, it can significantly improve user acquisition and engagement.

For additional support or questions, refer to the main documentation or contact the development team. 