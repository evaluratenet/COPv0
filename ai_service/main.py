from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import httpx
import os
import logging
from datetime import datetime
import json
import asyncio

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Circle of Peers AI Service",
    description="AI moderation and peer response service for Circle of Peers platform",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class PostContent(BaseModel):
    post_id: int
    user_id: int
    peer_id: str
    content: str
    room_id: Optional[int] = None
    thread_id: Optional[int] = None

class ModerationResult(BaseModel):
    flagged: bool
    violation_type: Optional[str] = None
    severity: Optional[int] = None
    reason: Optional[str] = None
    confidence: Optional[float] = None

class AIResponse(BaseModel):
    content: str
    context_aware: bool
    response_type: str  # "moderation", "peer_insight", "coaching"

class WebhookPayload(BaseModel):
    event_type: str  # "post_created", "post_edited", "user_flagged"
    post_id: int
    user_id: int
    peer_id: str
    content: str
    room_id: Optional[int] = None
    thread_id: Optional[int] = None
    flag_reason: Optional[str] = None

# Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DISCOURSE_API_KEY = os.getenv("DISCOURSE_API_KEY")
DISCOURSE_API_USERNAME = os.getenv("DISCOURSE_API_USERNAME", "system")
DISCOURSE_BASE_URL = os.getenv("DISCOURSE_BASE_URL", "http://discourse:80")

# Violation types mapping
VIOLATION_TYPES = {
    "solicitation": "Promotion or sales content",
    "pii": "Personal identifiable information", 
    "harassment": "Hostile or inappropriate tone",
    "confidential": "Company confidential information",
    "off_topic": "Content unrelated to discussion",
    "spam": "Repeated or automated content",
    "identity_leak": "Revealing personal identity",
    "inappropriate": "Inappropriate content for professional forum"
}

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "Circle of Peers AI Service",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "openai_configured": bool(OPENAI_API_KEY),
        "discourse_configured": bool(DISCOURSE_API_KEY),
        "services": {
            "openai": "configured" if OPENAI_API_KEY else "missing",
            "discourse": "configured" if DISCOURSE_API_KEY else "missing"
        }
    }

@app.post("/webhook", response_model=ModerationResult)
async def webhook_handler(payload: WebhookPayload, background_tasks: BackgroundTasks):
    """
    Handle webhooks from Discourse for real-time moderation
    """
    try:
        logger.info(f"Received webhook: {payload.event_type} for post {payload.post_id}")
        
        # Process moderation in background
        background_tasks.add_task(process_webhook_moderation, payload)
        
        return ModerationResult(flagged=False)  # Immediate response
        
    except Exception as e:
        logger.error(f"Webhook processing error: {str(e)}")
        raise HTTPException(status_code=500, detail="Webhook processing error")

@app.post("/moderate", response_model=ModerationResult)
async def moderate_content(post: PostContent):
    """
    Moderate post content for violations
    """
    try:
        # Basic content validation
        if not post.content.strip():
            return ModerationResult(flagged=False)
        
        # Check for obvious violations first (regex-based)
        basic_violations = check_basic_violations(post.content)
        if basic_violations:
            return ModerationResult(
                flagged=True,
                violation_type=basic_violations["type"],
                severity=basic_violations["severity"],
                reason=basic_violations["reason"],
                confidence=0.9
            )
        
        # AI-based moderation if OpenAI is configured
        if OPENAI_API_KEY:
            ai_result = await moderate_with_ai(post.content)
            return ai_result
        
        # Fallback to basic checks only
        return ModerationResult(flagged=False)
        
    except Exception as e:
        logger.error(f"Error in moderation: {str(e)}")
        raise HTTPException(status_code=500, detail="Moderation service error")

@app.post("/reply", response_model=AIResponse)
async def generate_peer_response(post: PostContent):
    """
    Generate AI peer response for threads
    """
    try:
        if not OPENAI_API_KEY:
            raise HTTPException(status_code=500, detail="OpenAI not configured")
        
        # Generate context-aware response
        response = await generate_ai_response(post.content, post.room_id)
        
        return AIResponse(
            content=response["content"],
            context_aware=response["context_aware"],
            response_type="peer_insight"
        )
        
    except Exception as e:
        logger.error(f"Error generating AI response: {str(e)}")
        raise HTTPException(status_code=500, detail="AI response generation error")

@app.post("/flag", response_model=dict)
async def create_user_flag(post: PostContent, violation_type: str, reason: str):
    """
    Create a user flag for a post (called by Discourse when user flags content)
    """
    try:
        # Validate violation type
        if violation_type not in VIOLATION_TYPES:
            raise HTTPException(status_code=400, detail="Invalid violation type")
        
        # Log the flag
        logger.info(f"User flag created: Post {post.post_id}, Type: {violation_type}, Reason: {reason}")
        
        # In a real implementation, you would create the flag in Discourse's database
        # For now, we'll just return success
        return {
            "success": True,
            "flag_id": f"flag_{post.post_id}_{datetime.utcnow().timestamp()}",
            "violation_type": violation_type,
            "reason": reason
        }
        
    except Exception as e:
        logger.error(f"Error creating user flag: {str(e)}")
        raise HTTPException(status_code=500, detail="Flag creation error")

@app.post("/test/flag")
async def test_moderation():
    """
    Test endpoint for development
    """
    return {
        "test_posts": [
            {
                "content": "Hey everyone, I have a great business opportunity to share...",
                "expected_violation": "solicitation"
            },
            {
                "content": "My email is john.doe@company.com and my phone is 555-1234",
                "expected_violation": "pii"
            },
            {
                "content": "You're all idiots and this discussion is worthless",
                "expected_violation": "harassment"
            },
            {
                "content": "I work at Google and we're about to launch a new product...",
                "expected_violation": "confidential"
            },
            {
                "content": "What's everyone's favorite pizza topping?",
                "expected_violation": "off_topic"
            }
        ]
    }

# User verification models
class UserVerificationData(BaseModel):
    user_info: dict
    application_data: dict
    criteria: List[dict]

class VerificationResult(BaseModel):
    recommendation: str  # "approve", "reject", "review_required"
    confidence_score: float
    risk_factors: List[dict]
    analysis: dict

@app.post("/verify", response_model=VerificationResult)
async def verify_user(verification_data: UserVerificationData):
    """
    AI-assisted user verification for registration
    """
    try:
        if not OPENAI_API_KEY:
            raise HTTPException(status_code=500, detail="OpenAI not configured")
        
        # Analyze user verification data
        result = await analyze_user_verification(verification_data)
        
        return VerificationResult(**result)
        
    except Exception as e:
        logger.error(f"Error in Vera's user verification: {str(e)}")
        raise HTTPException(status_code=500, detail="Vera verification service error")

# Background task for webhook processing
async def process_webhook_moderation(payload: WebhookPayload):
    """Process moderation for webhook events"""
    try:
        # Create post content object
        post_content = PostContent(
            post_id=payload.post_id,
            user_id=payload.user_id,
            peer_id=payload.peer_id,
            content=payload.content,
            room_id=payload.room_id,
            thread_id=payload.thread_id
        )
        
        # Moderate the content
        result = await moderate_content(post_content)
        
        if result.flagged:
            logger.info(f"Webhook moderation flagged post {payload.post_id}: {result.violation_type}")
            
            # In a real implementation, you would create the flag in Discourse
            # For now, we'll just log it
            await notify_discourse_of_flag(payload.post_id, result)
        
    except Exception as e:
        logger.error(f"Background webhook processing error: {str(e)}")

async def notify_discourse_of_flag(post_id: int, result: ModerationResult):
    """Notify Discourse of AI flag (placeholder for webhook back to Discourse)"""
    try:
        # This would be a webhook call back to Discourse to create the flag
        logger.info(f"Would notify Discourse of flag for post {post_id}: {result.violation_type}")
        
    except Exception as e:
        logger.error(f"Error notifying Discourse of flag: {str(e)}")

# Helper functions
def check_basic_violations(content: str) -> Optional[dict]:
    """Basic regex-based violation checking"""
    import re
    
    # Solicitation patterns
    solicitation_patterns = [
        r"connect you with",
        r"business opportunity",
        r"let me introduce you to",
        r"sales pitch",
        r"promotional offer",
        r"investment opportunity",
        r"get rich quick",
        r"make money fast"
    ]
    
    # PII patterns
    pii_patterns = [
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',  # Email
        r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',  # Phone
        r'\b\d{3}-\d{2}-\d{4}\b',  # SSN
        r'\b\d{5}[-.]?\d{4}\b',  # ZIP+4
    ]
    
    # Harassment patterns
    harassment_patterns = [
        r"you're an idiot",
        r"you're all stupid",
        r"this is worthless",
        r"shut up",
        r"you're incompetent",
        r"this is garbage"
    ]
    
    # Confidential information patterns
    confidential_patterns = [
        r"confidential",
        r"internal only",
        r"not for public",
        r"company secret",
        r"proprietary information"
    ]
    
    content_lower = content.lower()
    
    # Check solicitation
    for pattern in solicitation_patterns:
        if re.search(pattern, content_lower):
            return {
                "type": "solicitation",
                "severity": 3,
                "reason": "Contains promotional or sales content"
            }
    
    # Check PII
    for pattern in pii_patterns:
        if re.search(pattern, content):
            return {
                "type": "pii",
                "severity": 4,
                "reason": "Contains personal identifiable information"
            }
    
    # Check harassment
    for pattern in harassment_patterns:
        if re.search(pattern, content_lower):
            return {
                "type": "harassment",
                "severity": 5,
                "reason": "Contains hostile or inappropriate language"
            }
    
    # Check confidential
    for pattern in confidential_patterns:
        if re.search(pattern, content_lower):
            return {
                "type": "confidential",
                "severity": 4,
                "reason": "Contains confidential or proprietary information"
            }
    
    return None

async def moderate_with_ai(content: str) -> ModerationResult:
    """AI-based moderation using OpenAI"""
    try:
        import openai
        
        client = openai.OpenAI(api_key=OPENAI_API_KEY)
        
        prompt = f"""
        Analyze this post for violations. Return JSON with:
        - flagged: boolean
        - violation_type: string (solicitation, pii, harassment, confidential, off_topic, spam, identity_leak, inappropriate)
        - severity: integer (1-5, 5 being most severe)
        - reason: string
        - confidence: float (0-1)
        
        Post content: "{content}"
        """
        
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a content moderator for a professional executive forum. Be strict but fair."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1
        )
        
        result_text = response.choices[0].message.content
        result = json.loads(result_text)
        
        return ModerationResult(**result)
        
    except Exception as e:
        logger.error(f"AI moderation error: {str(e)}")
        return ModerationResult(flagged=False)

async def generate_ai_response(content: str, room_id: Optional[int]) -> dict:
    """Generate AI peer response"""
    try:
        import openai
        
        client = openai.OpenAI(api_key=OPENAI_API_KEY)
        
        # Context based on room type
        room_context = get_room_context(room_id)
        
        prompt = f"""
        You are Peer AI #0000, an AI assistant in a private C-level executive forum.
        Provide a thoughtful, strategic response that adds value to this discussion.
        Keep it professional, constructive, and focused on leadership/strategy.
        
        Room context: {room_context}
        Discussion: "{content}"
        
        Respond as a helpful peer, not as an AI.
        """
        
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are Peer AI #0000, a strategic advisor and peer in an executive forum."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=300
        )
        
        return {
            "content": response.choices[0].message.content,
            "context_aware": True
        }
        
    except Exception as e:
        logger.error(f"AI response generation error: {str(e)}")
        raise

def get_room_context(room_id: Optional[int]) -> str:
    """Get context based on room type"""
    room_contexts = {
        1: "HR & People - Leadership, talent management, organizational culture",
        2: "Finance & Capital - Financial strategy, fundraising, M&A",
        3: "Corporate Strategy - Growth planning, competitive dynamics, transformation",
        4: "Sales & GTM - Go-to-market strategy, customer acquisition",
        5: "Mergers & Acquisitions - Due diligence, integration, deal strategy",
        6: "Leadership & Mental Load - Executive challenges, work-life balance"
    }
    
    return room_contexts.get(room_id, "General executive discussion")

async def analyze_user_verification(verification_data: UserVerificationData) -> dict:
    """
    Analyze user verification data using AI
    """
    try:
        user_info = verification_data.user_info
        criteria = verification_data.criteria
        
        # Build analysis prompt
        prompt = build_verification_prompt(user_info, criteria)
        
        # Call OpenAI for analysis
        response = await call_openai_for_verification(prompt)
        
        # Parse and structure the response
        result = parse_verification_response(response, user_info)
        
        return result
        
    except Exception as e:
        logger.error(f"Error in Vera's user verification analysis: {str(e)}")
        return fallback_verification_analysis(user_info)

def build_verification_prompt(user_info: dict, criteria: List[dict]) -> str:
    """Build the verification analysis prompt"""
    
    prompt = f"""
You are Vera, an AI verification specialist for Circle of Peers, a private forum for C-level executives. Your role is to thoroughly analyze applications and provide detailed assessments with confidence scores.

**User Information:**
- Name: {user_info.get('name', 'Not provided')}
- Email: {user_info.get('email', 'Not provided')}
- Company: {user_info.get('company', 'Not provided')}
- Title: {user_info.get('title', 'Not provided')}
- LinkedIn: {user_info.get('linkedin_url', 'Not provided')}
- Bio: {user_info.get('bio', 'Not provided')}
- Location: {user_info.get('location', 'Not provided')}

**Verification Criteria:**
"""
    
    for criterion in criteria:
        prompt += f"- {criterion['name']}: {criterion['description']} (Weight: {criterion['weight']})\n"
    
    prompt += """
**Analysis Instructions:**
1. Evaluate if this person appears to be a legitimate C-level executive or equivalent senior leader
2. Check for consistency in professional information
3. Identify any risk factors or red flags
4. Assess the overall credibility and suitability for the platform

**Response Format:**
Provide your analysis in the following JSON format:
{
    "recommendation": "approve|reject|review_required",
    "confidence_score": 0.0-1.0,
    "risk_factors": [
        {
            "name": "Risk factor name",
            "description": "Description of the risk",
            "severity": "high|medium|low"
        }
    ],
    "analysis": {
        "executive_role_verified": true/false,
        "professional_credibility": "high|medium|low",
        "risk_level": "high|medium|low",
        "notes": "Additional analysis notes"
    }
}

**Important Guidelines:**
- Only approve if there's strong evidence of C-level or equivalent executive role
- Reject if there are significant red flags or inconsistencies
- Request review if the case is unclear or borderline
- Be conservative in approvals to maintain platform quality
"""
    
    return prompt

async def call_openai_for_verification(prompt: str) -> str:
    """Call OpenAI API for verification analysis"""
    try:
        import openai
        
        client = openai.AsyncOpenAI(api_key=OPENAI_API_KEY)
        
        response = await client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are Vera, a professional verification specialist for Circle of Peers. You provide accurate, conservative assessments with detailed reasoning and confidence scores."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=1000
        )
        
        return response.choices[0].message.content
        
    except Exception as e:
        logger.error(f"Vera OpenAI API error: {str(e)}")
        raise

def parse_verification_response(response: str, user_info: dict) -> dict:
    """Parse the AI verification response"""
    try:
        # Try to extract JSON from response
        import re
        
        # Find JSON in the response
        json_match = re.search(r'\{.*\}', response, re.DOTALL)
        if json_match:
            result = json.loads(json_match.group())
        else:
            # Fallback parsing
            result = fallback_verification_analysis(user_info)
            result['analysis']['notes'] = f"Failed to parse Vera's response: {response[:200]}"
            return result
        
        # Validate and structure the response
        return {
            'recommendation': result.get('recommendation', 'review_required'),
            'confidence_score': float(result.get('confidence_score', 0.5)),
            'risk_factors': result.get('risk_factors', []),
            'analysis': result.get('analysis', {})
        }
        
    except Exception as e:
        logger.error(f"Error parsing Vera's verification response: {str(e)}")
        return fallback_verification_analysis(user_info)

def fallback_verification_analysis(user_info: dict) -> dict:
    """Fallback verification analysis when Vera is unavailable"""
    
    risk_factors = []
    confidence_score = 0.5
    
    # Basic checks
    if not user_info.get('title'):
        risk_factors.append({
            'name': 'Missing Job Title',
            'description': 'No job title provided',
            'severity': 'high'
        })
        confidence_score -= 0.2
    
    if not user_info.get('company'):
        risk_factors.append({
            'name': 'Missing Company',
            'description': 'No company information provided',
            'severity': 'high'
        })
        confidence_score -= 0.2
    
    if not user_info.get('linkedin_url'):
        risk_factors.append({
            'name': 'Missing LinkedIn',
            'description': 'No LinkedIn profile provided',
            'severity': 'medium'
        })
        confidence_score -= 0.1
    
    # Email domain check
    email = user_info.get('email', '')
    if email and '@' in email:
        domain = email.split('@')[1].lower()
        personal_domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com']
        if domain in personal_domains:
            risk_factors.append({
                'name': 'Personal Email',
                'description': f'Using personal email domain: {domain}',
                'severity': 'medium'
            })
            confidence_score -= 0.1
    
    # Determine recommendation
    if confidence_score >= 0.7:
        recommendation = 'approve'
    elif confidence_score <= 0.3:
        recommendation = 'reject'
    else:
        recommendation = 'review_required'
    
    return {
        'recommendation': recommendation,
        'confidence_score': max(confidence_score, 0.0),
        'risk_factors': risk_factors,
        'analysis': {
            'executive_role_verified': confidence_score >= 0.6,
            'professional_credibility': 'medium' if confidence_score >= 0.5 else 'low',
            'risk_level': 'high' if len([rf for rf in risk_factors if rf['severity'] == 'high']) >= 2 else 'medium',
            'notes': 'Fallback analysis performed due to Vera service unavailability'
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 