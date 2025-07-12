# Circle of Peers — System Design Document

## 1. System Objective

Create a secure, anonymous, high-trust discussion platform where C-level professionals can engage in peer-based forums, supported by human moderation and context-aware AI agents.

## 2. Architecture Overview

**Frontend:**

* Framework: Discourse (Ruby on Rails-based)
* Custom Plugins: ID masking, room access control, AI injection, 2FA enhancements

**Backend:**

* Ruby on Rails (Discourse Core)
* Python Microservices for AI (moderation + peer AI agent)
* Redis for session/state caching

**Database:**

* PostgreSQL (Discourse default)

**Storage:**

* Wasabi S3-compatible object storage (documents, logs, backups)

**Authentication:**

* Email/password with enforced 2FA (email-based OTP)
* Session concurrency control with inactivity monitoring
* Single-session enforcement with auto-logout

**AI Services:**

* OpenAI (moderation endpoint + GPT agents)
* Perspective API for toxicity scoring (optional backup)

**Payment Processing:**

* Stripe integration for subscription management
* 30-day trial period with automatic billing

**Hosting:**

* VPS or cloud-based (AWS Lightsail, DigitalOcean, etc.)
* Dockerized Discourse deployment

---

## 3. Core Modules

### 3.1 User Management

* Sign-up with LinkedIn, title, company, email(s)
* Optional dual email verification
* **Vera AI verification** with confidence scoring and risk assessment
* Admin review of AI recommendations with final decision authority
* Peer ID assignment upon approval
* Fixed pseudonymous ID (Peer #xxx) for all interactions
* **Users must agree to the [Community Guidelines](/community-guidelines) at signup**
* **Email Change Verification**: Risk-based approval system for email changes, especially corporate-to-private changes

### 3.2 Conference & Breakout Rooms

* Top-level rooms (e.g., HR, Strategy, Finance)
* Nested breakout rooms (user-created with 10 votes)
* Thread-based discussions
* AI Peer Agent embedded per room (opt-out available)

### 3.3 Notifications & Alerts

* Email alerts for:

  * New thread comments (noreply@circleofpeers.net)
  * AI-flagged violations (moderation@circleofpeers.net)
  * Weekly digest (optional) (noreply@circleofpeers.net)
  * Billing notifications (billing@circleofpeers.net)
  * Support inquiries (support@circleofpeers.net)

### 3.4 AI Moderation & User Flagging

* **AI Auto-flagging**: GPT + regex/entity scan for 8 violation types
* **User Flagging**: Members can flag posts with violation categorization
* **Dual Detection**: Both AI and user flags go to admin review
* **Severity-Based Actions**: Automatic post hiding, user suspension based on violation level
* **Admin Dashboard**: Comprehensive interface for flag management with filtering and statistics
* **Violation History**: Complete audit trail logged by Peer ID
* **Community Guidelines**: Behavioral and moderation standards are defined in a dedicated page, referenced from Terms and Conditions and signup.

### 3.5 Admin Interface

* Dashboard: user stats, active rooms, flags
* **Vera verification assessment review** with confidence scores and risk factors
* Reference verification review (verification@circleofpeers.net)
* Post moderation queue (moderation@circleofpeers.net)
* Violation history per user
* Billing management (billing@circleofpeers.net)

### 3.6 Resource Library

* Book reviews and article summaries (peer or admin-submitted)
* Admin-curated featured section
* Comments allowed; AI summarization possible

### 3.7 Marketing Support Feature

* Suggested copy for users to post on LinkedIn/Xing
* No Peer ID or internal data sharing

---

## 4. Data Models (Simplified)

### User

* id
* peer\_id (fixed, anonymized, 4-digit format)
* email\_primary
* email\_secondary
* linkedin\_url
* company, title
* role = \[user, admin]
* verified = true/false
* violation\_count
* subscription\_status
* session\_status

### Thread

* id
* room\_id
* breakout\_id
* peer\_id (author)
* content
* timestamp

### Room

* id
* type = \[conference, breakout]
* parent\_id (null for top level)
* title, description
* created\_by, upvote\_count

### PostFlag

* id
* post_id
* flagged_by_user_id (optional)
* flagged_by_peer_id
* violation_type_id
* reason
* source = \[user, ai, admin]
* status = \[pending, approved, rejected, resolved]
* severity (1–5)
* confidence (AI only)
* reviewed_by_admin_id
* reviewed_at
* admin_notes
* created_at
* updated_at

### Subscription

* id
* user_id
* stripe_subscription_id
* stripe_customer_id
* status = \[trialing, active, past_due, canceled]
* plan_type = \[monthly, annual]
* amount (in cents)
* currency
* current_period_start
* current_period_end
* trial_start
* trial_end
* canceled_at
* created_at
* updated_at

### PaymentMethod

* id
* subscription_id
* stripe_payment_method_id
* type = \[card, bank_account]
* brand
* last4
* exp_month
* exp_year
* is_default
* created_at
* updated_at

### BillingEvent

* id
* subscription_id
* event_type
* stripe_event_id
* success
* metadata (JSONB)
* created_at

### ViolationType

* id
* name = \[solicitation, pii, harassment, confidential, off_topic, spam, identity_leak, inappropriate]
* description
* severity (1–5)
* ai_detectable (boolean)
* user_reportable (boolean)

---

## 5. Security Requirements

* HTTPS everywhere
* Email 2FA on every login
* Max 1 active session per user with inactivity monitoring
* 10-minute inactivity warning, 15-minute auto-logout
* Wasabi S3 bucket with restricted IAM roles
* No data resale or advertising
* Secure payment processing via Stripe

---

## 6. AI Integration Summary

* Peer AI posts in public threads only
* GPT-based agent trained on leadership, strategy, growth
* Contextual response injection on selected threads
* Admins can disable AI per room
* Moderation AI scores + labels posts automatically, routes to dashboard

---

## 7. Deployment

* Discourse Docker + plugins hosted on VPS
* Python FastAPI app for AI microservices
* Nightly backup to Wasabi
* Cloudflare for DDoS protection and DNS

---

## 8. Future Enhancements (Phase 2+)

* Mobile app wrapper (via React Native)
* User voting system for insightful posts
* More advanced role-based access
* Video or audio breakout room options

---

## 9. Compliance & Logging

* GDPR-aligned: user data deletion on request
* Audit trail of admin actions
* AI decisions logged (flag reasons, confidence scores)

---

## 10. Step-by-Step Development Process

### Phase 1: Infrastructure Setup

1. Register domain and configure DNS (e.g. `circleofpeers.net`).
2. Set up VPS or cloud server (e.g. DigitalOcean, AWS Lightsail).
3. Install and configure Discourse using Docker.
4. Enable SSL and HTTPS using Let's Encrypt.
5. Configure SMTP for transactional email delivery.
6. Set up Wasabi bucket with proper access controls.
7. Install Cloudflare or similar CDN for DNS protection and DDoS mitigation.

### Phase 2: Discourse Core Configuration

1. Configure categories for conference rooms.
2. Enable and test email-based 2FA.
3. Disable public user registration; enable invite/admin-verified sign-up.
4. Modify user templates to add:

   * Primary and secondary email field
   * LinkedIn profile URL
   * Job title and company name
5. Install Discourse plugins for tagging, user notes, and moderation tools.

### Phase 3: Custom Feature Development

1. Create plugin for fixed pseudonymous Peer IDs.
2. Develop plugin to restrict breakout room creation to 10+ upvotes.
3. Add **AI-assisted verification workflow** including:

   * Vera analysis of user applications with confidence scoring
   * Risk factor identification and assessment
   * Admin review of Vera's recommendations
   * Reference email submission and response validation
4. Implement activity panel showing followed/commented threads.
5. Add user moderation log and violation tracker.
6. Enforce session uniqueness (one active session per user).

### Phase 4: AI Integration & Moderation

1. Set up FastAPI app to handle:

   * Content moderation using GPT/OpenAI + regex patterns
   * Violation classification and flagging for 8 violation types
   * Webhook processing for real-time moderation
2. Create webhook integration between Discourse and AI service.
3. Develop comprehensive admin dashboard for flag management:

   * List view with filtering and sorting
   * Detail view with post content and flag context
   * Bulk actions for approve/reject/suspend
   * Statistics and analytics
4. Implement user flagging system:

   * Flag button on posts with violation type selection
   * Modal interface for flag submission
   * Integration with admin review queue
5. Train Peer AI (#000) agent on sample leadership topics and enable GPT-assisted replies.
6. Add toggle to allow users to opt out of AI-generated replies in rooms.

### Phase 5: Resource Section & Notifications

1. Create `Resources` category and custom page for articles/book reviews.
2. Develop content submission form with moderation step.
3. Set up notification triggers:

   * Post replies
   * Followed thread activity
   * AI flag alerts (admin-only)
4. Configure email templates for notifications.

### Phase 6: Billing and Subscription

1. Integrate Stripe or similar service for subscription handling.
2. Set 30-day trial logic with automated upgrade path.
3. Restrict access if subscription is not completed after trial.
4. Ensure users can cancel/manage billing securely.

### Phase 7: Testing & Launch

1. Conduct internal alpha testing across all workflows.
2. Perform load testing and AI moderation testing.
3. Conduct 3rd-party security audit (especially 2FA and storage).
4. Recruit first 20 test users and onboard manually.
5. Refine UX and admin tools based on feedback.
6. Go live with controlled access and begin inviting new users.


