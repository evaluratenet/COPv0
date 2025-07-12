# Technical Documentation - Landing Page Plugin

This document provides detailed technical information for developers working with the Circle of Peers Landing Page Plugin.

## Code Structure

```
plugins/landing-page/
├── plugin.rb                           # Main plugin configuration
├── controllers/
│   └── landing_controller.rb          # Route handling and page rendering
├── models/
│   └── community_statistics.rb        # Statistics calculation logic
├── jobs/
│   └── update_community_statistics.rb # Background job for updates
├── views/
│   └── landing/
│       ├── index.html.erb            # Main landing page
│       ├── about.html.erb            # About page
│       ├── features.html.erb         # Features page
│       ├── pricing.html.erb          # Pricing page
│       └── contact.html.erb          # Contact page
├── javascripts/
│   └── landing-page.js               # Frontend enhancements
├── stylesheets/
│   └── landing-page.scss             # Custom styling
└── README.md                          # User documentation
```

## Plugin Configuration

### plugin.rb

The main plugin file handles:
- Plugin metadata and versioning
- Route registration
- Asset loading
- Background job scheduling
- Event hooks for statistics updates

Key methods:
- `enabled?` - Plugin activation check
- `on_after_initialize` - Route registration and job scheduling
- `add_to_serializer` - Custom serializer additions

## Database Models

### CommunityStatistics

Located in `models/community_statistics.rb`

#### Core Methods

```ruby
def self.calculate_all_statistics
  # Main method that calculates all community statistics
  # Returns a hash with all calculated values
end

def self.total_members
  # Returns total number of approved users
end

def self.weekly_active_users
  # Returns users active in the last 7 days
end

def self.peer_connections_initiated
  # Returns count of peer connection requests
end

def self.contributing_members_percentage
  # Returns percentage of users who have posted
end

def self.members_by_level
  # Returns distribution of members by level
end

def self.discussions_by_category
  # Returns discussion count by category
end
```

#### Caching Strategy

Statistics are cached using Discourse's built-in caching:
- Cache key: `community_statistics`
- Cache duration: 1 hour (configurable)
- Cache invalidation: On user events and background job completion

## Controllers

### LandingController

Located in `controllers/landing_controller.rb`

#### Routes Handled

```ruby
get '/landing' => 'landing#index'
get '/landing/about' => 'landing#about'
get '/landing/features' => 'landing#features'
get '/landing/pricing' => 'landing#pricing'
get '/landing/contact' => 'landing#contact'
```

#### Key Methods

```ruby
def index
  # Main landing page with dynamic statistics
end

def about
  # About page rendering
end

def features
  # Features page rendering
end

def pricing
  # Pricing page rendering
end

def contact
  # Contact page rendering
end

private

def load_community_statistics
  # Loads and caches community statistics
end
```

## Background Jobs

### UpdateCommunityStatistics

Located in `jobs/update_community_statistics.rb`

#### Job Configuration

```ruby
class Jobs::UpdateCommunityStatistics < Jobs::Base
  def execute(args)
    # Recalculates all community statistics
    # Updates cache with new values
    # Triggers frontend refresh for admin users
  end
end
```

#### Scheduling

The job is scheduled to run:
- Every hour by default (configurable)
- On specific user events (approvals, new posts, contact requests)
- Manually via admin interface

#### Event Triggers

Statistics are updated when:
- New user is approved
- New post is created
- New contact request is made
- Background job completes

## Frontend JavaScript

### landing-page.js

Located in `javascripts/landing-page.js`

#### Features

1. **Auto-refresh for Admins**
   - Detects admin users
   - Automatically refreshes statistics
   - Visual feedback during updates

2. **Manual Refresh**
   - Refresh button for admins
   - Loading indicators
   - Error handling

3. **Statistics Display**
   - Dynamic number formatting
   - Smooth animations
   - Responsive updates

#### Key Functions

```javascript
function refreshStatistics() {
  // Fetches updated statistics from server
  // Updates DOM with new values
  // Provides visual feedback
}

function formatNumber(number) {
  // Formats numbers with appropriate suffixes
  // Handles large numbers (K, M, B)
}

function animateValue(element, start, end, duration) {
  // Animates number changes
  // Smooth transitions between values
}
```

## Styling

### landing-page.scss

Located in `stylesheets/landing-page.scss`

#### Design System

- **Colors**: Consistent with Circle of Peers branding
- **Typography**: Modern, readable fonts
- **Layout**: Responsive Bootstrap grid
- **Components**: Custom styled elements

#### Key Classes

```scss
.landing-hero {
  // Hero section styling
}

.community-snapshot {
  // Statistics section styling
}

.stat-card {
  // Individual statistic card styling
}

.cta-section {
  // Call-to-action styling
}
```

## API Integration

### Statistics Endpoint

The plugin provides a JSON endpoint for statistics:

```
GET /landing/statistics.json
```

Response format:
```json
{
  "total_members": 1234,
  "weekly_active_users": 567,
  "peer_connections_initiated": 89,
  "contributing_members_percentage": 75.5,
  "members_by_level": {
    "GM": 234,
    "MD": 345,
    "VP": 456,
    "C-Level": 123
  },
  "discussions_by_category": {
    "Leadership": 123,
    "Strategy": 234,
    "Operations": 345
  }
}
```

## Performance Optimization

### Database Queries

1. **Efficient Counting**
   - Uses `count()` instead of `length`
   - Leverages database indexes
   - Minimizes N+1 queries

2. **Caching Strategy**
   - Redis-based caching
   - Configurable cache duration
   - Cache invalidation on events

3. **Background Processing**
   - Heavy calculations in background jobs
   - Non-blocking user requests
   - Configurable update intervals

### Memory Management

1. **Query Optimization**
   - Limits result sets
   - Uses pagination where appropriate
   - Avoids loading unnecessary data

2. **Asset Optimization**
   - Minified JavaScript and CSS
   - Efficient asset loading
   - Browser caching headers

## Security Considerations

### Access Control

1. **Route Protection**
   - Landing pages are public
   - Statistics endpoint requires authentication
   - Admin features restricted to admin users

2. **Data Sanitization**
   - Input validation on all forms
   - XSS protection in templates
   - SQL injection prevention

3. **Rate Limiting**
   - API endpoint rate limiting
   - Background job throttling
   - Cache abuse prevention

## Testing

### Unit Tests

Create tests for:
- Statistics calculation accuracy
- Background job execution
- Controller response handling
- JavaScript functionality

### Integration Tests

Test:
- End-to-end user flows
- Database integration
- Cache behavior
- Performance under load

### Manual Testing Checklist

- [ ] Landing page loads correctly
- [ ] Statistics display accurately
- [ ] Auto-refresh works for admins
- [ ] Background jobs execute properly
- [ ] Cache invalidation works
- [ ] Mobile responsiveness
- [ ] Cross-browser compatibility

## Deployment

### Installation Steps

1. **Plugin Installation**
   ```bash
   # Copy plugin to plugins directory
   cp -r landing-page /path/to/discourse/plugins/
   ```

2. **Database Migration**
   ```bash
   # Run any necessary migrations
   rake db:migrate
   ```

3. **Asset Compilation**
   ```bash
   # Compile assets
   rake assets:precompile
   ```

4. **Restart Services**
   ```bash
   # Restart Discourse services
   sudo systemctl restart discourse
   ```

### Configuration

1. **Enable Plugin**
   - Admin → Plugins → Landing Page → Enable

2. **Configure Settings**
   - Statistics refresh interval
   - Auto-refresh settings
   - Display options

3. **Verify Installation**
   - Visit `/landing` to confirm page loads
   - Check background job logs
   - Verify statistics calculation

## Monitoring

### Key Metrics

Monitor:
- Statistics calculation time
- Background job execution frequency
- Cache hit/miss ratios
- Page load times
- User engagement metrics

### Logging

Enable debug logging for:
- Statistics calculation
- Background job execution
- Cache operations
- User interactions

### Alerts

Set up alerts for:
- Failed background jobs
- High page load times
- Cache misses
- Database query performance

## Troubleshooting

### Common Issues

1. **Statistics Not Updating**
   - Check background job logs
   - Verify cache configuration
   - Ensure database permissions

2. **Performance Issues**
   - Review database queries
   - Check cache hit rates
   - Monitor server resources

3. **JavaScript Errors**
   - Check browser console
   - Verify asset compilation
   - Test cross-browser compatibility

### Debug Commands

```bash
# Check background job status
rake jobs:work

# Clear cache
rails console
Rails.cache.clear

# Check plugin status
rails console
Plugin.find_by(name: 'landing-page').enabled?
```

## Future Enhancements

### Planned Features

1. **Advanced Analytics**
   - User engagement metrics
   - Conversion tracking
   - A/B testing support

2. **Customization Options**
   - Theme customization
   - Content management interface
   - Multi-language support

3. **Integration Features**
   - Social media integration
   - Email marketing tools
   - CRM integration

### Extension Points

The plugin is designed for easy extension:
- Modular statistics calculation
- Pluggable background jobs
- Customizable views
- Extensible JavaScript framework 