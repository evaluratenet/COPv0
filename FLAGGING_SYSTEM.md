# Circle of Peers - Flagging System

## 🚨 Overview

The Circle of Peers platform implements a comprehensive flagging system that allows both **users** and **AI agents** to flag posts that violate platform terms. This ensures content quality and maintains the professional environment.

## 🔧 How It Works

### 1. **User Flagging**
- Users can flag posts by clicking the "Flag" button on any post
- They select a violation type from predefined categories
- Provide optional reason for the flag
- Flag is sent to admin review queue

### 2. **AI Flagging**
- AI automatically scans all new posts and edits
- Uses both regex patterns and OpenAI for detection
- Flags are created automatically for detected violations
- High-severity flags trigger immediate admin notifications

### 3. **Admin Review**
- Admins review all flags in the admin panel
- Can approve, reject, or take additional actions
- Automatic actions based on violation severity
- Email notifications for urgent flags

## 📋 Violation Types

| Type | Severity | Description | Auto-Action |
|------|----------|-------------|-------------|
| **Harassment** | 5 (Critical) | Hostile or inappropriate tone | Delete post + suspend user |
| **PII** | 4 (High) | Personal identifiable information | Hide post + warn user |
| **Confidential** | 4 (High) | Company confidential information | Hide post + warn user |
| **Identity Leak** | 4 (High) | Revealing personal identity | Hide post + warn user |
| **Solicitation** | 3 (Medium) | Promotion or sales content | Hide post |
| **Inappropriate** | 3 (Medium) | Inappropriate for professional forum | Hide post |
| **Spam** | 3 (Medium) | Repeated or automated content | Hide post |
| **Off-Topic** | 2 (Minor) | Content unrelated to discussion | Flag for review |

## 🎯 Flagging Flow

### User Flagging Process
```
1. User clicks "Flag" button on post
2. Modal opens with violation type selection
3. User selects violation type and provides reason
4. Flag is created in database (status: pending)
5. Admin receives notification
6. Admin reviews and takes action
```

### AI Flagging Process
```
1. New post is created/edited
2. Background job calls AI service
3. AI analyzes content using regex + OpenAI
4. If violation detected, flag is created
5. High-severity flags trigger immediate admin notification
6. Admin reviews and takes action
```

## 🔍 Detection Methods

### Regex-Based Detection
- **Solicitation**: "business opportunity", "connect you with", "sales pitch"
- **PII**: Email addresses, phone numbers, SSNs
- **Harassment**: "you're an idiot", "this is worthless"
- **Confidential**: "confidential", "internal only", "company secret"

### AI-Based Detection
- Uses OpenAI GPT-3.5-turbo for nuanced analysis
- Context-aware violation detection
- Confidence scoring for each flag
- Handles complex cases that regex misses

## 📊 Admin Dashboard

### Flag Management
- **List View**: All flags with filtering and sorting
- **Detail View**: Full post content and flag details
- **Bulk Actions**: Approve/reject multiple flags
- **Statistics**: Flag counts by type, source, severity

### Quick Actions
- **Approve Flag**: Take action on post (hide/delete)
- **Reject Flag**: Dismiss false positive
- **Suspend User**: For severe violations
- **Add Notes**: Admin comments on decisions

## 🚨 Severity-Based Actions

### Critical (Severity 5)
- **Action**: Delete post + suspend user for 30 days
- **Examples**: Harassment, threats, severe violations

### High (Severity 4)
- **Action**: Hide post + send warning email to user
- **Examples**: PII, confidential info, identity leaks

### Medium (Severity 3)
- **Action**: Hide post
- **Examples**: Solicitation, inappropriate content, spam

### Minor (Severity 2)
- **Action**: Flag for review (post remains visible)
- **Examples**: Off-topic content

## 📧 Notifications

### Admin Notifications
- **Email**: Detailed flag information with quick action links
- **In-App**: Real-time notifications for urgent flags
- **Dashboard**: Visual indicators for pending flags

### User Notifications
- **Warning Emails**: When posts are hidden for violations
- **Suspension Notices**: When accounts are suspended
- **Appeal Process**: 7-day window to appeal decisions

## 🔄 Integration Points

### Discourse Integration
- **Post Actions**: Custom flag action type
- **Admin Panel**: Flag management interface
- **User Interface**: Flag button on posts
- **Background Jobs**: AI moderation processing

### AI Service Integration
- **Webhooks**: Real-time post processing
- **API Endpoints**: Moderation and flag creation
- **Background Tasks**: Async processing for performance

## 🧪 Testing

### Test Cases
```javascript
// Test posts for different violation types
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

### API Testing
```bash
# Test AI moderation
curl -X POST http://localhost:8000/moderate \
  -H "Content-Type: application/json" \
  -d '{
    "post_id": 1,
    "user_id": 1,
    "peer_id": "Peer #001",
    "content": "Hey everyone, I have a great business opportunity..."
  }'

# Test user flagging
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
```

## 📈 Monitoring & Analytics

### Key Metrics
- **Flag Volume**: Total flags per day/week
- **False Positive Rate**: Rejected flags vs approved
- **Response Time**: Time from flag to admin action
- **Violation Distribution**: Flags by type and severity

### Dashboard Views
- **Real-time**: Current pending flags
- **Historical**: Flag trends over time
- **User Analysis**: Users with multiple violations
- **AI Performance**: AI vs user flag accuracy

## 🔐 Security Considerations

### Data Protection
- **Anonymity**: User flags don't reveal flagger identity to admins
- **Audit Trail**: All admin actions are logged
- **Appeal Process**: Users can appeal decisions
- **Data Retention**: Flags are archived after resolution

### Access Control
- **Admin Only**: Flag management restricted to admins
- **User Permissions**: Users can only flag posts, not manage flags
- **API Security**: Webhook authentication for AI service
- **Rate Limiting**: Prevent flag spam

## 🚀 Future Enhancements

### Planned Features
- **Machine Learning**: Improve AI detection accuracy
- **Community Moderation**: Allow trusted users to review flags
- **Automated Actions**: Auto-approve certain violation types
- **Analytics Dashboard**: Advanced reporting and insights
- **Mobile Support**: Flag posts from mobile app

### Integration Opportunities
- **Slack Notifications**: Real-time admin alerts
- **Zapier Integration**: Custom workflows
- **Reporting API**: Export flag data for analysis
- **Third-party Tools**: Integration with external moderation services 