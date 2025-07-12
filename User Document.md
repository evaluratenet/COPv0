### 1. LOGIN PAGE

**URL:** `www.circleofpeers.net`

**Features:**

* Email and password login
* **Two-Factor Authentication (2FA) via email**
* "Forgot password" functionality
* Clear link to sign-up page
* Reminder: "Your seat is personal. Do not share access."

**2FA Flow:**

1. User enters email + password
2. If valid, system sends a 6-digit code to registered email
3. Code is valid for 10 minutes
4. User enters code on `/verify-code` page
5. If verified, user is logged in and previous sessions are terminated

---

### 2. SIGN-UP PAGE

**URL:** `/signup`

**Required Fields:**

* Full Name
* Primary Email Address (private or corporate accepted)
* LinkedIn profile URL
* Company & Title
* **Referrer Email Address** (email of the user who referred you)
* Consent checkbox to terms of use, community rules, and verification policy (link to `/terms`)

**Additional Verification for Private Emails:**

* If a private email (e.g., Gmail, Yahoo) is used, the user must also provide a **secondary email from a corporate domain**
* A verification code will be sent to the corporate email
* Access will only be granted once both email addresses are verified
* **Note**: Users can change their email address later through account preferences, but changing from corporate to private email requires admin approval

**Terms and Conditions Acknowledgment:**

* **MANDATORY CHECKBOX**: "I have read, understood, and agree to the Terms and Conditions"
* **MANDATORY CHECKBOX**: "I have read and agree to the Community Guidelines" ([View Guidelines](/community-guidelines))

**Key Terms Summary (Displayed on Signup Page):**

> **IMPORTANT - Please Read Before Proceeding:**
> 
> By joining Circle of Peers, you agree to the following key terms:
> 
> ✅ **No Solicitation**: Promoting products, services, or business opportunities is strictly prohibited and will result in immediate account suspension
> 
> ✅ **No Personal Data Sharing**: Revealing personal contact information, addresses, or private details is not allowed
> 
> ✅ **No Harassment**: Hostile, threatening, or inappropriate behavior will result in immediate suspension
> 
> ✅ **No Confidential Information**: Sharing company secrets or proprietary information is prohibited
> 
> ✅ **Immediate Suspension**: Violation of these terms will result in immediate account suspension without refund
> 
> ✅ **Anonymous Participation**: Your real identity will remain confidential; you will be assigned an anonymous Peer ID
> 
> ✅ **Subscription Terms**: 30-day free trial, then $50/month or $500/year. Cancel anytime.
> 
> [Read Full Terms and Conditions](/terms)

**User must agree to the following before proceeding:**

* I confirm that I meet the role and seniority requirements (C-level executive or equivalent)
* I will not share my access or login credentials with others
* I agree to keep all discussions confidential and within the platform
* I understand that off-limits topics and activities are prohibited as outlined in the Terms of Use
* I acknowledge that failure to comply may result in immediate account suspension or removal
* I agree to maintain professional and respectful behavior at all times

**Process:**

* User fills form with required information including referrer email
* **Referrer validation** - system verifies referrer exists and has active subscription
* **AI automatically analyzes the application** using multiple criteria:
  * Executive role verification (job title, company, LinkedIn)
  * Professional credibility assessment
  * Email domain analysis (corporate vs personal)
  * Company verification and legitimacy check
  * Risk factor identification
* **AI provides recommendation** (approve/reject/review) with confidence score
* **Admin receives detailed assessment** via verification@circleofpeers.net
* Admin reviews AI analysis and makes final decision
* Upon approval, Peer ID is assigned and access granted with 30-day free trial
* **Referral tracking** - when user pays for subscription, referrer receives 1 month free

**Required Fields:**

* Full Name
* Email address (corporate recommended)
* LinkedIn profile URL
* Company & Title
* **Referrer Email Address** (email of the user who referred you)
* Consent checkbox to terms of use & verification policy

**Process:**

* User fills form
* System auto-generates a numbered ID upon approval (e.g., Participant #0042)
* Admin receives verification request
* Admin verifies via LinkedIn and reference link
* Upon approval, access is granted with 30-day free trial

---

### 3. CONDITIONS OF USAGE PAGE

**URL:** `/terms`

**Page Layout:**

> **Circle of Peers - Terms and Conditions**
> 
> **Effective Date:** [Date]
> 
> **Last Updated:** [Date]
> 
> ---
> 
> **IMPORTANT NOTICE:**
> 
> By using the Circle of Peers platform, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. Violation of these terms will result in immediate account suspension without refund.
> 
> **Key Highlights:**
> 
> 🚨 **IMMEDIATE SUSPENSION FOR VIOLATIONS:**
> - No solicitation of products or services
> - No sharing of personal data or contact information
> - No harassment or inappropriate behavior
> - No sharing of confidential company information
> - No identity disclosure without mutual consent
> 
> 📋 **Full Terms and Conditions:**
> 
> [Complete Terms and Conditions content displayed here]
> 
> ---
> 
> **Contact Information:**
> - Email: admin@circleofpeers.net
> - Support hours: Monday-Friday, 9 AM - 5 PM EST
> - Legal correspondence: [Legal Address]

**Key Sections:**

1. **Acceptance of Terms**
   By accessing the platform, you agree to be bound by these Terms.

2. **Eligibility Requirements**
   Must be C-level executive or equivalent senior leadership position.

3. **Account Security**
   - One account per person
   - Mandatory 2FA
   - No credential sharing
   - Single session enforcement with inactivity monitoring
   - 10-minute inactivity warning, 15-minute auto-logout

4. **Privacy and Anonymity**
   - Fixed anonymous Peer IDs
   - Real identities not disclosed
   - Encrypted data protection
   - No third-party data sharing

5. **Acceptable Use Policy**
   **VIOLATION OF THESE TERMS WILL RESULT IN IMMEDIATE ACCOUNT SUSPENSION:**
   - No solicitation or promotion
   - No personal data sharing
   - No harassment or inappropriate behavior
   - No confidential information disclosure
   - No identity revelation without consent
   - No spam or off-topic content

6. **Content Moderation**
   - AI-powered violation detection
   - User flagging system
   - Admin review process
   - Severity-based actions

7. **Subscription Terms**
   - 30-day free trial
   - $50 USD/month or $500 USD/year after trial
   - Automatic billing via Stripe
   - Cancel anytime with access until end of billing period

8. **Termination**
   - Immediate suspension for violations
   - No refunds for violations
   - Data deletion within 30 days

9. **Limitation of Liability**
   - Maximum liability limited to subscription fees
   - No liability for indirect damages
   - Users assume responsibility for actions

10. **Contact and Support**
    - **General Support**: support@circleofpeers.net
    - **Billing Issues**: billing@circleofpeers.net
    - **Moderation Appeals**: moderation@circleofpeers.net
    - **Administrative**: admin@circleofpeers.net
    - 7-day appeal window for moderation decisions
    - Emergency contact for urgent issues

---

### 4. REFERENCE VERIFICATION PAGE

**URL:** `/verify`

**Process:**

* New user must submit:

  * A professional reference email (current/former peer or direct report)
  * That reference receives a verification link with 3 questions:

    * Is this person currently or formerly in a C-level or similar role?
    * Would you consider this person a trustworthy peer?
    * Optional comments
* Reference must submit response for user to proceed

---

### 5. DASHBOARD (POST-LOGIN)

**URL:** `/dashboard`

**Overview:**

* Displays a grid/list of available **conference rooms**
* Each room shows:

  * Title (e.g., HR & People)
  * Brief description
  * Number of **new activities** (threads, replies)
  * Last updated timestamp
* Clickable to enter each room
* Right side panel shows **user activity feed** with links to followed or participated threads

---

### 6. CONFERENCE ROOMS & RESOURCES

**Format:**
All conference rooms and breakout rooms are structured as **discussion forums**, where users can initiate and participate in anonymous, topic-specific threads. Select rooms may also feature **AI-generated peer insights**.

**AI Agent (Peer AI #0000):**

* Occasionally provides thoughtful, context-aware commentary on discussion threads
* Offers strategic frameworks, leadership models, or prompting questions relevant to C-level challenges
* Clearly labeled as an AI-generated contribution
* Designed to complement—not replace—peer discussions
* Posts only in public threads and never reads private messages
* Users may opt out of seeing AI responses per room
  All conference rooms and breakout rooms are structured as **discussion forums**, where users can initiate and participate in anonymous, topic-specific threads.
  **URL:** `/rooms`

**Available Rooms at Launch:**

* HR & People
* Finance & Capital
* Corporate Strategy
* Sales & GTM
* Mergers & Acquisitions
* Leadership & Mental Load

**Room Structure:**

* Each conference room contains multiple **breakout rooms** (sub-topics or threads)
* Users can suggest new breakout rooms under each main room (e.g., "Talent Retention" under HR)
* Breakout room creation requires 10 peer upvotes
* Admins review to prevent duplication and ensure relevance

**Each Room Includes:**

* **Intro Section** – defines the scope and intent of the main room
* **Breakout Rooms** – titled sub-topics with discussions
* **Thread Posts** – numbered, anonymous peer contributions
* **Connect Request Button** – to initiate peer connection (mutual opt-in)

**Example Room Intro:**

> **Room: Corporate Strategy**
> For candid discussions on growth planning, competitive dynamics, transformation, and business model innovation. Share dilemmas, frameworks, and reflections.

---

### 7. ARTICLES & BOOK REVIEWS

**URL:** `/resources`

**Purpose:**
A dedicated section for curated content from management and business publications, as well as peer-submitted book reviews. This is intended to foster continuous learning and shared reflection among members.

**Content Types:**

* Summaries or highlights of management articles from HBR, McKinsey, Bain, etc.
* Peer-written commentary or takeaways from recent reads
* Book reviews focused on leadership, strategy, operations, innovation, and resilience

**Interaction:**

* Users may comment anonymously on each post
* Content is moderated to ensure quality and relevance
* Members can suggest articles for posting via a submission form

**Moderation:**

* Admins curate featured content
* Peer-submitted book reviews may be promoted upon admin approval

---

### 8. REQUESTING NEW ROOMS

**URL:** `/rooms/suggest`

**Mechanism:**

* Users may only suggest **new breakout rooms within existing conference rooms**
* New top-level conference rooms will be curated and introduced by admins based on demand or emerging needs

---

### 8. USER IDENTITY

* Each user is assigned a **fixed anonymous ID** (e.g., Peer #0138) upon approval
* This ID does not change across sessions, allowing for continuity in discussions and recognition of contributions
* All user actions are displayed using their fixed numbered ID
* No profile photos, bios, or public identity info are visible
* User may request a private connection, and identity is revealed only upon mutual consent
* Internal system tracks user activity via secure permanent identifiers not visible to the community
* All user actions are displayed using numbered IDs only (e.g., Peer #0138)
* No profile photos, bios, or public identity info
* User may request a private connection, and identity is revealed only upon mutual consent

---

### 9. USER ACTIVITY PANEL

* A vertical panel on the right side of the interface lists each user's **recent activity**
* Displays:

  * Threads posted by the user
  * Threads the user commented on
  * Threads the user is following
  * **Update indicators** if new replies have been added since last visit
* Each item in the panel is **clickable for quick access**

**Email Notifications:**

* User receives an email when another participant comments on a thread they:

  * Started
  * Have commented on
  * Are following
* Notification includes a link to the thread and mentions the responding participant ID (e.g., "Peer #0027 has responded")

---

### 10. ADMIN FUNCTIONS

* **User Management:**
  * Vet new users and references
  * Monitor login session behavior (e.g., concurrent access)
  * Review breakout room requests and ensure policy compliance

* **Content Moderation Dashboard:**
  * Comprehensive flag management interface with filtering and sorting
  * Review both AI-flagged and user-flagged content
  * View post content, violation details, and flagger information
  * Take actions: approve, reject, suspend user, add notes
  * Bulk actions for multiple flags
  * Statistics and analytics on flag volume and types

* **Flag Review Process:**
  * Receive email alerts for all flagged content (includes reason, severity, and link)
  * View user violation history by Peer ID (number of flags, types, timestamps)
  * Determine admin action: approve, edit, delete, or suspend user
  * Severity-based automatic actions (hide post, suspend user, etc.)

* **AI Integration:**
  * **Vera AI Verification:** Comprehensive analysis of user applications with confidence scoring
  * **Content Moderation:** AI continuously reviews public thread content for 8 violation types
  * **Dual Detection:** Both AI and user flags go to admin review queue
  * **Real-time Processing:** Webhook integration for immediate flag creation
  * **Risk Assessment:** Vera identifies potential risk factors and red flags in applications

---

### 11. TECH & SECURITY

* Enforced single-session login
* **Email-based Two-Factor Authentication (2FA)** required for all logins
* Encrypted data at rest and in transit
* Secure cloud hosting (AWS or equivalent)
* No user tracking or advertising

---

### 12. USER ONBOARDING FLOW

* Once approved, the user receives a welcome email confirming their seat number (e.g., Peer #0042)
* Upon first login, the user is guided through:

  * A short intro about the platform's purpose and anonymity model
  * Agreement to the Member Pledge (below)
  * Suggested first steps: visit dashboard, read the latest featured post, explore conference rooms, post or reply
  * Option to help grow the platform by sharing a public post (see section 18)
* Once approved, the user receives a welcome email confirming their seat number (e.g., Peer #0042)
* Upon first login, the user is guided through:

  * A short intro about the platform's purpose and anonymity model
  * Agreement to the Member Pledge (below)
  * Suggested first steps: visit dashboard, read the latest featured post, explore conference rooms, post or reply

---

### 13. COMMUNITY ETIQUETTE / MEMBER PLEDGE

* Speak with respect and clarity
* Value the time and insights of peers
* Maintain confidentiality
* No personal attacks, trolling, or dominance
* No self-promotion or selling
* Contribute thoughtfully — if you’re here, your voice matters
* **COP will not entertain any requests for user details** – All member identities remain strictly confidential

---

### 14. REFERRAL SYSTEM

**How It Works:**

* **During Signup**: New users must provide the email address of the user who referred them
* **Referrer Validation**: System verifies the referrer exists and has an active subscription
* **Referral Tracking**: Referral is tracked through the user's journey
* **Reward Activation**: When the referred user pays for their first subscription, the referrer receives 1 month free
* **Automatic Processing**: Rewards are applied automatically to the referrer's subscription

**Referral Benefits:**

* **For Referrers**: Earn 1 month free subscription for each successful referral
* **For New Users**: Join through a trusted connection, maintaining platform quality
* **For Platform**: Organic growth through existing member networks

**Referral Rules:**

* Only active subscribers can be referrers
* Referrer must have an active subscription when referral is completed
* One referral reward per referred user
* Rewards expire after 90 days if not applied
* Referrals are tracked anonymously (Peer IDs only)

**Managing Referrals:**

* View your referrals at `/my/referrals`
* Track referral status and rewards
* See pending and completed referrals
* Monitor reward application status

---

### 15. FREQUENTLY ASKED QUESTIONS (FAQ)

* **Can I use a private email address?**
  Yes. However, if you sign up with a private email (e.g., Gmail), you must also verify a corporate email as a secondary step to confirm your professional background.

* **What happens if I don’t post within 30 days?**
  You will receive a warning, and may be suspended until you resume participation.

* **Can I invite others to join?**
  Yes, via the referral system. When someone signs up using your email as their referrer, and they pay for a subscription, you'll receive 1 month free. Share your email address with potential members for them to use during signup.

* **Can I use a personal email address?**
  Corporate or professional emails are preferred, but not strictly required. If you sign up with a private email, you must also provide a corporate email for verification. You can change your email later through account preferences, but changing from corporate to private email requires admin approval.

* **How do I delete my account?**
  Submit a deletion request through support. Your data will be permanently removed.

* **How do I report inappropriate content?**
  Click the "Flag" button on any post, select the violation type, and provide a reason. Both AI and human admins review all flags.

* **What happens when I flag a post?**
  Your flag is sent to the admin review queue. Admins will review and take appropriate action based on the violation severity. Your identity remains anonymous in the flagging process.

* **What types of violations can I flag?**
  You can flag posts for: solicitation, personal information, harassment, confidential info, off-topic content, spam, identity leaks, or inappropriate content.

* **What happens if my post gets flagged?**
  Depending on the violation severity: posts may be hidden, you may receive a warning, or in severe cases, your account may be suspended. You'll be notified of any actions taken.

* **Can I change my email address after signing up?**
  Yes, but the process depends on your current email type:
  
  **Corporate → Private Email**: Requires admin approval and additional verification. If you have a corporate email backup on file, the process is faster. If not, admins may require additional verification.
  
  **Private → Corporate Email**: Usually auto-approved after email verification, as this improves your verification status.
  
  **Corporate → Corporate Email**: Requires email verification but is typically auto-approved.
  
  To change your email, go to your account preferences and submit a change request. You'll receive a verification email to confirm the new address.

* **What happens if I change from a corporate to private email?**
  The system will:
  1. Check if you have a corporate email backup on file
  2. If yes: Process with medium risk assessment
  3. If no: Flag for high-risk admin review
  4. Admins may require additional verification or reject the change
  5. You'll be notified of the decision via email

* **How long does email change approval take?**
  - **Auto-approved changes**: Immediate after email verification
  - **Admin-reviewed changes**: 24-48 hours typically
  - **High-risk changes**: May take longer with additional verification required

---

### 15. PRIVACY & DATA TRANSPARENCY

* No user tracking or ad-related data sharing
* User IDs are pseudonymous and never publicly linked to real identity
* Login logs and sessions are encrypted and stored securely
* Only posts flagged by users are reviewed by admins
* Data will never be sold or shared with third parties

---

### 16. REPORTING & APPEALS

* Inappropriate content, misuse, or technical issues can be reported via the in-app "Report" button or by emailing support
* Admins review reports within 48 hours
* If a user is suspended or removed, they will be notified by email
* Users may appeal actions within 7 days through a secure form or email review request

---

### 17. CONTENT SUBMISSION GUIDELINES (ARTICLES & REVIEWS)

* Posts should include a summary, personal insight, or key takeaway
* Sources must be cited if content is drawn from publications
* Submissions must be relevant to leadership, business strategy, or personal growth
* AI-assisted content is permitted, but must be reviewed and customized by the submitter
* Submissions will be reviewed by admins for quality before being featured

---

### 18. OPTIONAL MARKETING SUPPORT FROM MEMBERS

**Purpose:**
To help grow the value of the platform, members are encouraged to share their experience on professional networks such as LinkedIn or Xing. Participation is completely voluntary.

**Why this matters:**
The more diverse, high-quality C-level peers who join, the more valuable the conversations become for everyone.

**Suggested Post Copy (Editable):**

> I've just joined an anonymous, verified network of C-level leaders called **Circle of Peers**. No profiles. No noise. Just real discussions on leadership, growth, and decision-making.
>
> Every member is verified. Every seat is equal. Every post is anonymous.
>
> If you're at the top and feel like you have nowhere to turn — this space was built for you.
>
> Learn more or request to join: \[insert landing page link]

**Instructions:**

* Copy and paste the above into your preferred platform
* Feel free to adjust for your voice or region
* Avoid revealing your Peer ID or any internal details

### 19. PRIVACY SETTINGS & CONTACT REQUESTS

**URL:** `/my/privacy-settings`

**Privacy Controls:**

Users have complete control over their profile visibility and contactability through privacy settings:

**Profile Visibility Options:**
- **Profile Hidden**: Complete privacy - no other users can see your profile
- **Profile Visible**: Other users can see your profile (with customizable field visibility)
- **Field-Level Control**: Choose which details to show: Name, Company, Title, Email

**Contact Request Settings:**
- **Accept Contact Requests**: Allow other users to send you contact requests
- **Reject Contact Requests**: Block all contact requests from other users

**Default Settings:**
- Profile visibility: **OFF** (hidden by default)
- Contact requests: **OFF** (not accepting by default)
- All profile fields: **OFF** (no details shown by default)

**Contact Request Process:**
1. User enables "Accept Contact Requests" in privacy settings
2. **Only active subscribers can send contact requests**
3. Other users can send contact requests with optional messages
4. Target user receives notification and can approve/reject
5. If approved, both users receive contact information
6. If rejected, requester is notified (no reason required)

**Subscription Requirements:**
- **Contact requests are only available to active subscribers**
- Non-subscribers will not see contact request options
- Contact buttons are hidden for users who don't accept contact requests
- Trial period users can send contact requests

**Privacy Levels:**
- **Hidden**: Profile completely hidden from other users
- **Minimal**: Profile visible but no personal details shown
- **Limited**: Some profile details visible to other users
- **Open**: Most profile details visible to other users

**Admin Controls:**
- Admins can view all privacy settings
- Admins can manage contact request approvals
- Admins can override privacy settings if needed for moderation

### 20. USER BLOCKING

**URL:** `/my/blocked-users`

**Blocking System:**

Users can block specific members to prevent unwanted interactions:

**How to Block a User:**
- Click on a user's profile or username
- Select "Block User" option
- Optionally provide a reason for the block
- Block takes effect immediately

**What Happens When You Block Someone:**
- **Mutual Block**: Both users cannot interact with each other
- **No Posts**: Cannot see or respond to each other's posts
- **No Messages**: Cannot send private messages to each other
- **No Contact Requests**: Cannot send contact requests to each other
- **Profile Hidden**: Cannot view each other's profiles
- **User Lists**: Blocked users are filtered from user lists

**Managing Your Blocks:**
- **View Blocked Users**: See all users you have blocked
- **Unblock Users**: Remove blocks to restore normal interaction
- **Block History**: View your blocking activity and reasons

**When You Are Blocked:**
- You will receive a notification when blocked
- You cannot interact with the user who blocked you
- You can continue using the platform normally with other users
- Contact support if you believe a block was made in error

**Admin Controls:**
- Admins can view all user blocks
- Admins can remove blocks if needed
- Admins can override blocking for moderation purposes

**Blocking Guidelines:**
- Use blocking for harassment, inappropriate behavior, or unwanted contact
- Do not block users for legitimate disagreements
- Contact support if you experience persistent issues
- Blocks can be removed by the user who created them or by administrators

---

### 21. SUBSCRIPTION INFORMATION

**Subscription Status Display:**

Users can view their subscription information in multiple places:

**User Profile:**
- **Subscription Status**: Active, Trial, Past Due, Canceled, or Inactive
- **Plan Details**: Monthly or Annual plan with pricing
- **End Date**: When your current subscription period ends
- **Time Remaining**: Days or months remaining in your subscription
- **Next Billing Date**: When your next payment will be processed
- **Trial Days**: Remaining trial days (if applicable)

**Billing Dashboard:**
- **URL**: `/billing`
- **Complete Details**: Full subscription information and management
- **Payment Methods**: Add, update, or remove payment methods
- **Billing History**: View past invoices and payments
- **Subscription Actions**: Cancel, upgrade, or modify subscription

**Subscription Information Available:**
- **Current Status**: Active, trial, past due, canceled, or inactive
- **Plan Type**: Monthly ($50/month) or Annual ($500/year)
- **Amount**: Monthly or annual cost
- **End Date**: When subscription expires (e.g., "December 15, 2024")
- **Time Remaining**: "3 months remaining" or "15 days remaining"
- **Next Billing**: When next payment will be charged
- **Trial Status**: Days remaining in trial period

**Notifications:**
- **Trial Ending**: Warning when trial has 7 days or less remaining
- **Payment Due**: Reminder when payment is past due
- **Subscription Expiring**: Notification when subscription is about to end
- **Payment Failed**: Alert when payment method fails

**Subscription Management:**
- **Upgrade/Downgrade**: Change between monthly and annual plans
- **Cancel Subscription**: Cancel with access until end of current period
- **Update Payment**: Change payment method or billing information
- **Reactivate**: Restart canceled subscription

---

### 22. REFERRAL REWARDS SYSTEM

**URL:** `/my/referrals`

**Referral Program:**

Earn one month free subscription for every paid user you invite to Circle of Peers!

**How It Works:**
1. **Generate Referral Code**: Active subscribers can generate a unique referral code
2. **Share Your Code**: Share your referral link with colleagues and peers
3. **Track Referrals**: Monitor your referral activity and conversion status
4. **Earn Rewards**: Get 1 month free for each referral that converts to paid subscription

**Referral Process:**
- **Eligibility**: Only active subscribers can generate referral codes
- **Referral Link**: Your unique URL (e.g., `/referral/ABC123`)
- **Conversion Tracking**: Referrals are tracked when new users sign up
- **Reward Application**: Automatic 1-month subscription extension upon conversion

**Reward Details:**
- **Reward**: 1 month free subscription per successful referral
- **Conversion**: Referral converts when user upgrades to paid subscription
- **Automatic Application**: Rewards are applied immediately upon conversion
- **Stackable**: Multiple referrals = multiple free months
- **No Expiration**: Rewards are applied to current subscription

**Referral Dashboard:**
- **Total Referrals**: Number of users who signed up with your code
- **Successful Conversions**: Number of referrals who became paid subscribers
- **Pending Referrals**: Referrals still in trial period
- **Total Rewards**: Cumulative free months earned
- **Referral Code**: Your unique sharing link

**Admin Controls:**
- Admins can view all referral activity
- Admins can manually process rewards if needed
- Admins can override referral tracking for special cases
