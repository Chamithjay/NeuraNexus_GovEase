from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
import paypalrestsdk
import random
import string
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta
import redis
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
import json
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

load_dotenv()

# Initialize PayPal SDK
paypalrestsdk.configure({
    "mode": os.getenv("PAYPAL_MODE", "sandbox"),  # sandbox or live
    "client_id": os.getenv("PAYPAL_CLIENT_ID"),
    "client_secret": os.getenv("PAYPAL_CLIENT_SECRET")
})

# Redis for OTP storage (you can use in-memory dict for testing)
try:
    redis_client = redis.Redis(host='localhost', port=6379, db=0)
except:
    # Fallback to in-memory storage
    redis_client = {}

router = APIRouter()

# Pydantic models
class PaymentCreateRequest(BaseModel):
    reference_number: str
    amount: float
    currency: str = "USD"
    description: str

class OTPSendRequest(BaseModel):
    reference_number: str
    phone_number: str
    payment_id: str

class OTPVerifyRequest(BaseModel):
    reference_number: str
    otp_code: str
    payment_id: str

DEFAULT_OTP = "871299"  # Always accept this for testing

# Helper functions
def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

def send_sms_otp(phone_number: str, otp: str):
    account_sid = os.getenv("TWILIO_ACCOUNT_SID")
    auth_token = os.getenv("TWILIO_AUTH_TOKEN")
    twilio_number = os.getenv("TWILIO_PHONE_NUMBER")

    if not account_sid or not auth_token or not twilio_number:
        raise ValueError("Twilio credentials or phone number not set in .env")

    try:
        client = Client(account_sid, auth_token)
        message = client.messages.create(
            body=f"Your GovEase verification code is: {otp}. Valid for 5 minutes.",
            from_=twilio_number,
            to=phone_number
        )
        print(f"✅ OTP sent to {phone_number}: SID={message.sid}")
        return message.sid  # return SID on success

    except TwilioRestException as e:
        # Raise exception with full Twilio info
        raise HTTPException(
            status_code=500,
            detail=f"Twilio Error: Code={e.code}, Status={e.status}, Msg={e.msg}"
        )

    except Exception as e:
        # Raise all other errors
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"SMS sending failed: {str(e)}")

def store_otp(key: str, otp: str, expiry_minutes: int = 5):
    """Store OTP with expiry"""
    try:
        if hasattr(redis_client, 'setex'):
            redis_client.setex(key, timedelta(minutes=expiry_minutes), otp)
        else:
            # Fallback for in-memory storage
            redis_client[key] = {
                'otp': otp,
                'expiry': datetime.now() + timedelta(minutes=expiry_minutes)
            }
    except Exception as e:
        print(f"OTP storage failed: {e}")

def verify_otp(key: str, provided_otp: str) -> bool:
    """Verify OTP"""
    try:
        # Always accept default OTP
        if provided_otp == DEFAULT_OTP:
            return True

        if hasattr(redis_client, 'get'):
            stored_otp = redis_client.get(key)
            if stored_otp:
                stored_otp = stored_otp.decode() if isinstance(stored_otp, bytes) else stored_otp
                return stored_otp == provided_otp
        else:
            # Fallback for in-memory storage
            stored_data = redis_client.get(key)
            if stored_data and stored_data['expiry'] > datetime.now():
                return stored_data['otp'] == provided_otp

        return False
    except Exception as e:
        print(f"OTP verification failed: {e}")
        return False

def generate_transaction_id():
    """Generate a random transaction ID"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))

@router.post("/payment/create")
async def create_payment(request: PaymentCreateRequest):
    """Create PayPal payment"""
    try:
        payment = paypalrestsdk.Payment({
            "intent": "sale",
            "payer": {
                "payment_method": "paypal"
            },
            "redirect_urls": {
                "return_url": "http://localhost:8000/payment/success",
                "cancel_url": "http://localhost:8000/payment/cancel"
            },
            "transactions": [{
                "item_list": {
                    "items": [{
                        "name": "Grade 1 Admission Application",
                        "sku": "grade1_admission",
                        "price": str(request.amount),
                        "currency": request.currency,
                        "quantity": 1
                    }]
                },
                "amount": {
                    "total": str(request.amount),
                    "currency": request.currency
                },
                "description": request.description,
                "custom": request.reference_number  # Store reference number
            }]
        })

        if payment.create():
            # Store payment info for later verification
            payment_data = {
                "payment_id": payment.id,
                "reference_number": request.reference_number,
                "amount": request.amount,
                "currency": request.currency,
                "status": "created",
                "created_at": datetime.now().isoformat()
            }
            
            return {
                "success": True,
                "payment_id": payment.id,
                "approval_url": next(link.href for link in payment.links if link.rel == "approval_url"),
                "message": "Payment created successfully"
            }
        else:
            raise HTTPException(status_code=400, detail=f"Payment creation failed: {payment.error}")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Payment creation error: {str(e)}")

@router.post("/payment/send-otp")
async def send_otp(request: OTPSendRequest):
    """Send OTP to the provided phone number"""
    # Validate phone number format
    if not request.phone_number.startswith("+"):
        raise HTTPException(status_code=400, detail="Phone number must be in E.164 format (e.g., +1234567890)")

    otp = generate_otp()
    otp_key = f"otp:{request.reference_number}:{request.payment_id}"
    store_otp(otp_key, otp, 5)

    # Send OTP via Twilio
    sid = send_sms_otp(request.phone_number, otp)

    return {
        "success": True,
        "message": "OTP sent successfully",
        "expires_in": 300,
        "sid": sid
    }

@router.post("/payment/verify-otp")
async def verify_payment_otp(request: OTPVerifyRequest):
    """Verify OTP and complete payment"""
    try:
        # Verify OTP
        otp_key = f"otp:{request.reference_number}:{request.payment_id}"
        
        if not verify_otp(otp_key, request.otp_code):
            raise HTTPException(status_code=400, detail="Invalid or expired OTP")
        
        # Execute PayPal payment (in real implementation, you'd execute the approved payment)
        # For demo purposes, we'll simulate successful payment
        transaction_id = generate_transaction_id()
        
        # Update payment status in database
        payment_result = {
            "success": True,
            "transaction_id": transaction_id,
            "payment_id": request.payment_id,
            "reference_number": request.reference_number,
            "status": "completed",
            "amount": 150.00,  # You'd get this from stored payment data
            "currency": "USD",
            "completed_at": datetime.now().isoformat()
        }
        
        # Clear OTP after successful verification
        try:
            if hasattr(redis_client, 'delete'):
                redis_client.delete(otp_key)
            else:
                redis_client.pop(otp_key, None)
        except:
            pass
        
        return payment_result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Payment verification error: {str(e)}")

@router.get("/payment/status/{reference_number}")
async def get_payment_status(reference_number: str):
    """Get payment status for a reference number"""
    try:
        # In a real implementation, you'd query your database
        # For demo purposes, return a mock response
        return {
            "reference_number": reference_number,
            "payment_status": "completed",
            "application_status": "submitted",
            "last_updated": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Status check error: {str(e)}")

@router.post("/payment/resend-otp")
async def resend_otp(request: OTPSendRequest):
    """Resend OTP"""
    return await send_otp(request)

@router.get("/payment/receipt/{reference_number}")
async def get_payment_receipt(reference_number: str):
    """Generate and return payment receipt"""
    try:
        # In a real implementation, you'd generate a PDF receipt
        # For now, return receipt data
        receipt_data = {
            "reference_number": reference_number,
            "service": "Grade 1 Admission Application",
            "amount": "LKR 150.00",
            "payment_method": "PayPal",
            "transaction_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "status": "Paid"
        }
        
        return {
            "success": True,
            "receipt_data": receipt_data,
            "download_url": f"/downloads/receipt_{reference_number}.pdf"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Receipt generation error: {str(e)}")