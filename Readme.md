# README: Circle of Peers Platform

## Overview

Circle of Peers is a private, invitation-based digital forum designed exclusively for verified C-level executives. The platform offers anonymous yet high-trust discussion environments on leadership, strategy, growth, HR, M\&A, and other executive themes.

It addresses the loneliness of leadership by enabling peer-to-peer exchange in a strictly confidential and curated space. Each participant is verified, pseudonymous, and assigned a unique, fixed Peer ID.

---

## Key Features

### 🛡️ Privacy & Security

* **Fixed anonymous Peer IDs** for all users
* **Two-Factor Authentication (2FA)** on all logins
* **Dual email verification** (corporate + private email for private email sign-ups)
* **Email Change Verification** system with risk-based admin approval for corporate-to-private email changes
* All content encrypted in transit and at rest
* No user tracking, profiling, or third-party data sharing

### 🔐 Onboarding & Verification

* Mandatory LinkedIn URL and company/title at signup
* Peer-provided reference (validated via form)
* **Vera AI verification** with confidence scoring and risk assessment
* Admin review of AI recommendations with final decision authority
* **30-day free trial**, followed by **USD 50/month or USD 500/year**

### 🧩 Conference Rooms

* Structured around **C-level topics** (HR, Strategy, Sales, etc.)
* Each room is a **discussion forum** containing breakout rooms for specific sub-topics
* Peer-generated threads are anonymous
* Optional connection requests with mutual opt-in
* Minimum 10 upvotes required to open a new breakout room

### 🤖 AI Capabilities

* **Peer AI #0000**: context-aware, labeled responses to stimulate discussion
* **AI moderation**: automatically flags posts with violations using regex + OpenAI analysis
* **User flagging**: members can flag posts for violations with detailed categorization
* **Admin review system**: comprehensive dashboard for managing flags with severity-based actions
* **Vera AI verification**: comprehensive analysis of user applications with confidence scoring and risk assessment
* **Session management**: inactivity monitoring with 10-minute warnings and auto-logout

### 📥 Articles & Reviews

* Featured content from McKinsey, HBR, Bain, etc.
* Peer-submitted summaries and reviews of leadership books and management articles
* Community commenting and admin curation

### 📢 Growth via Peer Support

* Members encouraged (not required) to share templated posts on LinkedIn/Xing to help attract other qualified members

---

## 🚨 Content Moderation

### Dual Flagging System
* **User Flagging**: Members can flag posts for violations with 8 violation categories
* **AI Flagging**: Automatic scanning of all posts using regex patterns + OpenAI analysis
* **Severity-Based Actions**: Automatic post hiding, user suspension based on violation severity
* **Admin Dashboard**: Comprehensive interface for reviewing and managing flags

### Violation Categories
* **Critical (5)**: Harassment, threats → Delete post + suspend user
* **High (4)**: PII, confidential info, identity leaks → Hide post + warn user  
* **Medium (3)**: Solicitation, inappropriate content, spam → Hide post
* **Minor (2)**: Off-topic content → Flag for review

---

## System Architecture

* **Frontend:** Discourse with custom plugins and theme modifications
* **Backend:** Ruby on Rails (Discourse core), Python microservices for AI moderation
* **AI Services:** OpenAI / Perspective API (flagging), embeddings for semantic thread detection
* **Payment Processing:** Stripe integration for subscription management
* **Storage:** Wasabi (S3-compatible) for documents, logs, media
* **Database:** PostgreSQL (Discourse default) with custom billing tables
* **Authentication:** Devise + email-based 2FA + session management

---

## Admin Functions

* Manage onboarding, verifications, user profiles
* **Review Vera verification assessments** with confidence scores and risk factors
* Moderate AI-flagged posts (view reasons, history, take action)
* View user activity logs, participation frequency
* Review and approve breakout room requests
* Manually escalate or suspend accounts with documented rationale
* **Billing management**: View subscriptions, payment history, revenue analytics
* **Session monitoring**: Track active sessions, force logout users

---

## Governance & Rules

* Strict no-solicitation and no-promotion policy
* Each user must post or respond **at least once every 30 days** to remain active
* All interactions governed by [Community Guidelines](/community-guidelines) and Member Pledge
* Inappropriate content is moderated based on clearly defined violation types
* **Session timeout**: 10-minute inactivity warning, 15-minute auto-logout
* **Subscription required**: Active subscription or trial required for platform access

---

### Community Guidelines

Circle of Peers maintains a dedicated [Community Guidelines](/community-guidelines) page outlining behavioral expectations, privacy and anonymity standards, moderation process, and consequences for violations. All users must agree to these guidelines at signup. The guidelines are accessible from the signup page, footer, and helpdesk.

---

## Deployment Notes

* Hosted on secure VPS or cloud instance (e.g., AWS Lightsail, DigitalOcean)
* Use Discourse’s Docker-based deploy toolchain
* Daily backups to Wasabi bucket
* SMTP server integration for email verification and notifications

---

## Contact

### 📧 **Email Addresses**

**📫 noreply@circleofpeers.net**
- System-generated emails (registration, notifications, 2FA codes)
- Configured with SPF, DKIM, and DMARC for deliverability
- No reply handling

**👥 support@circleofpeers.net**
- User inquiries and technical support
- Connected to helpdesk system
- Access issues and billing questions

**🧾 verification@circleofpeers.net**
- Reference checks during user onboarding
- Receives reference replies via secure links
- Monitored by admin team

**🛡 moderation@circleofpeers.net**
- AI and user flag notifications
- Direct moderation concerns from users
- Admin review notifications

**🧑‍💼 admin@circleofpeers.net**
- Main administrative contact
- Partner and vendor communications
- Legal requests and executive communications

**💰 billing@circleofpeers.net**
- Payment-related communications
- Receives Stripe automated receipts
- Invoice and billing support

### **Support & Resources**
- Support link: `/support`
- Landing page: www.circleofpeers.net

