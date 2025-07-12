# Circle of Peers Landing Page Plugin

A comprehensive landing page plugin for the Circle of Peers platform that provides an engaging entry point for new users with dynamic community statistics and modern design.

## Features

### Core Landing Page
- **Welcome Section**: Engaging hero section with platform introduction
- **Platform Purpose**: Clear explanation of the Circle of Peers mission
- **Key Features**: Highlighted platform capabilities
- **How It Works**: Step-by-step process explanation
- **Core Values**: Platform principles and commitments
- **Call-to-Action**: Sign-up encouragement with multiple entry points

### Dynamic Community Snapshot
- **Real-time Statistics**: Live community data including:
  - Total members count
  - Weekly active users
  - Peer connections initiated
  - Contributing members percentage
  - Member distribution by level (GM, MD, VP, C-Level)
  - Discussion categories breakdown
- **Auto-refresh**: Statistics update automatically for admin users
- **Background Processing**: Efficient caching and periodic updates
- **Event-driven Updates**: Statistics refresh on key user activities

### Additional Pages
- **About Page**: Detailed platform information
- **Features Page**: Comprehensive feature showcase
- **Pricing Page**: Membership options and pricing
- **Contact Page**: Contact information and support

## Installation

1. Place the plugin in your Discourse plugins directory:
   ```
   plugins/landing-page/
   ```

2. Enable the plugin in your Discourse admin panel:
   - Go to Admin → Plugins
   - Find "Landing Page" and click "Enable"

3. Configure the plugin settings (optional):
   - Update community statistics refresh interval
   - Customize display settings

## Configuration

### Plugin Settings

The plugin includes several configurable options in `Admin → Plugins → Landing Page`:

- **Statistics Refresh Interval**: How often to update community statistics (default: 1 hour)
- **Auto-refresh for Admins**: Enable/disable automatic statistics refresh for admin users
- **Display Settings**: Customize which statistics to show

### Routes

The plugin adds the following routes to your Discourse installation:

- `/landing` - Main landing page
- `/landing/about` - About page
- `/landing/features` - Features page
- `/landing/pricing` - Pricing page
- `/landing/contact` - Contact page

## Architecture

### Models

#### CommunityStatistics
Located in `models/community_statistics.rb`

Calculates real-time community statistics:
- Total members count
- Weekly active users (last 7 days)
- Peer connections initiated
- Contributing members percentage
- Member distribution by level
- Discussion categories

### Controllers

#### LandingController
Located in `controllers/landing_controller.rb`

Handles all landing page routes and provides:
- Landing page rendering with dynamic statistics
- Additional page routing (About, Features, Pricing, Contact)
- Statistics loading and caching

### Jobs

#### UpdateCommunityStatistics
Located in `jobs/update_community_statistics.rb`

Background job that:
- Periodically updates community statistics
- Runs every hour by default
- Triggers on key user events (approvals, new posts, contact requests)
- Efficiently caches results to minimize database load

### Views

#### Main Landing Page
Located in `views/landing/index.html.erb`

Features:
- Modern, responsive design
- Dynamic community snapshot section
- Professional styling with Bootstrap integration
- Mobile-friendly layout

### JavaScript

#### Landing Page Enhancement
Located in `javascripts/landing-page.js`

Provides:
- Auto-refresh functionality for admin users
- Visual feedback during statistics updates
- Manual refresh capability
- Smooth animations and transitions

## Database Integration

The plugin integrates with existing Discourse models:

- **User**: For member counts and activity tracking
- **Post**: For discussion statistics
- **Topic**: For category breakdowns
- **UserAction**: For activity tracking

## Performance Considerations

### Caching Strategy
- Statistics are cached for 1 hour by default
- Background job updates prevent blocking user requests
- Efficient database queries minimize load

### Background Processing
- Statistics updates run in background jobs
- Event-driven updates for immediate accuracy
- Configurable refresh intervals

## Customization

### Styling
The plugin uses Bootstrap classes and custom CSS. To customize:

1. Edit `stylesheets/landing-page.scss`
2. Modify view templates in `views/landing/`
3. Update JavaScript in `javascripts/landing-page.js`

### Content
To modify landing page content:

1. Edit `views/landing/index.html.erb` for main content
2. Update additional pages in `views/landing/`
3. Modify statistics calculation in `models/community_statistics.rb`

### Statistics
To add new statistics:

1. Add calculation method to `CommunityStatistics` model
2. Update the view to display the new statistic
3. Ensure the background job includes the new calculation

## Troubleshooting

### Common Issues

1. **Statistics not updating**
   - Check background job logs
   - Verify database permissions
   - Ensure plugin is properly enabled

2. **Landing page not accessible**
   - Verify plugin is enabled
   - Check route configuration
   - Ensure no conflicting plugins

3. **Performance issues**
   - Adjust statistics refresh interval
   - Review database query optimization
   - Check server resources

### Debug Mode
Enable debug logging by setting the log level in your Discourse configuration.

## Contributing

To contribute to this plugin:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This plugin is licensed under the same license as Discourse.

## Support

For support and questions:
- Check the Discourse community forums
- Review the plugin documentation
- Contact the development team

## Changelog

### Version 1.0.0
- Initial release with basic landing page
- Dynamic community statistics
- Background job processing
- Auto-refresh functionality
- Additional pages (About, Features, Pricing, Contact) 