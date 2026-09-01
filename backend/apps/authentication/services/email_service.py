import os
import logging
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.utils import timezone

logger = logging.getLogger('apps.authentication.email_service')

class HealthcareEmailService:
    """
    Unified Email Dispatch Service for CareLink Kerala
    Handles:
    - 6-digit OTP verification & password recovery
    - Appointment confirmations & digital pass links
    - Fundraiser donation receipts with 80G tax notes
    - Staff registration welcome letters
    - Diagnostic SMTP test delivery
    """

    @classmethod
    def _can_send_smtp(cls) -> bool:
        """Returns True if live SMTP credentials appear configured"""
        host_user = getattr(settings, 'EMAIL_HOST_USER', '')
        host_password = getattr(settings, 'EMAIL_HOST_PASSWORD', '')
        return bool(host_user and host_password)

    @classmethod
    def _dispatch(cls, subject: str, text_content: str, html_content: str, recipient: str) -> dict:
        """
        Dispatches email via Django SMTP if configured; otherwise logs simulated payload cleanly.
        """
        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', 'CareLink Kerala <noreply@carelink.kerala.gov.in>')

        if not recipient or '@' not in recipient:
            logger.warning(f"Invalid email address provided for dispatch: {recipient}")
            return {'status': 'error', 'message': f'Invalid email address: {recipient}'}

        if cls._can_send_smtp():
            try:
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=text_content,
                    from_email=from_email,
                    to=[recipient]
                )
                msg.attach_alternative(html_content, "text/html")
                msg.send(fail_silently=False)
                logger.info(f"Successfully sent live SMTP email to {recipient}: '{subject}'")
                return {
                    'status': 'success',
                    'mode': 'smtp',
                    'recipient': recipient,
                    'message': f"Email dispatched directly to {recipient} via SMTP."
                }
            except Exception as e:
                logger.error(f"SMTP Dispatch Error to {recipient}: {str(e)}")
                return {
                    'status': 'error',
                    'mode': 'smtp_failed',
                    'recipient': recipient,
                    'error': str(e),
                    'fallback_message': "SMTP send failed. Check host credentials."
                }
        else:
            # Local development / Sandboxed mode
            logger.info("=================================================================")
            logger.info(f"📧 [DEV EMAIL SIMULATION] To: {recipient} | Subject: {subject}")
            logger.info(f"Message Body:\n{text_content}")
            logger.info("=================================================================")
            return {
                'status': 'success',
                'mode': 'dev_simulation',
                'recipient': recipient,
                'message': f"OTP/Email dispatched to {recipient} (Dev Sandbox Mode - Add EMAIL_HOST_USER & PASSWORD to .env for live inbox delivery)."
            }

    @classmethod
    def send_otp_email(cls, recipient_email: str, otp_code: str, user_name: str = "CareLink User", context: str = "Password Recovery") -> dict:
        """Dispatches 6-digit OTP verification code with security instructions"""
        subject = f"🔐 Your CareLink Kerala Verification Code: {otp_code}"

        text_content = f"""Hello {user_name},

Your CareLink Kerala verification code for {context} is:

-------------------------
      {otp_code}
-------------------------

This code is valid for 10 minutes. 

SECURITY NOTICE: CareLink Kerala staff will NEVER ask for your OTP. Do not share this code with anyone.
If you did not request this verification code, please ignore this email.

Warm regards,
CareLink Kerala Healthcare Team
Government of Kerala • Department of Health
"""

        html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; margin: 0; padding: 24px; color: #1e293b; }}
  .card {{ max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }}
  .header {{ background: linear-gradient(135deg, #059669, #0d9488); padding: 28px 24px; text-align: center; color: #ffffff; }}
  .header h1 {{ margin: 0; font-size: 22px; font-weight: 700; letter-spacing: -0.5px; }}
  .header p {{ margin: 6px 0 0 0; font-size: 13px; opacity: 0.9; }}
  .body {{ padding: 32px 28px; text-align: center; }}
  .otp-box {{ margin: 24px auto; padding: 18px 28px; background: #f0fdf4; border: 2px dashed #059669; border-radius: 12px; display: inline-block; }}
  .otp-code {{ font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #059669; font-family: monospace; }}
  .expiry {{ font-size: 12px; color: #64748b; margin-top: 8px; font-weight: 500; }}
  .warning {{ background: #fffbeb; border: 1px solid #fef3c7; color: #92400e; padding: 12px 16px; border-radius: 8px; font-size: 12px; margin-top: 24px; text-align: left; }}
  .footer {{ background: #f8fafc; padding: 18px 24px; text-align: center; font-size: 11px; color: #94a3b8; border-top: 1px solid #f1f5f9; }}
</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>🏥 CareLink Kerala</h1>
      <p>Palliative, Clinical & Hospital Network</p>
    </div>
    <div class="body">
      <h2 style="font-size: 18px; margin: 0 0 12px 0; color: #0f172a;">Verification Code ({context})</h2>
      <p style="font-size: 14px; line-height: 1.5; color: #475569; margin: 0;">Hello <strong>{user_name}</strong>,<br>Use the following 6-digit one-time password (OTP) to securely complete your verification:</p>
      
      <div class="otp-box">
        <div class="otp-code">{otp_code}</div>
        <div class="expiry">⏳ Valid for 10 minutes only</div>
      </div>

      <div class="warning">
        ⚠️ <strong>Security Advisory:</strong> CareLink Kerala healthcare officers or doctors will never call or message asking for your OTP code. Never share this code with anyone.
      </div>
    </div>
    <div class="footer">
      This is an automated security communication from CareLink Kerala.<br>
      © {timezone.now().year} CareLink Kerala • Government of Kerala Health Network
    </div>
  </div>
</body>
</html>"""

        return cls._dispatch(subject, text_content, html_content, recipient_email)

    @classmethod
    def send_appointment_confirmation_email(cls, recipient_email: str, patient_name: str, doctor_name: str, specialty: str, hospital_name: str, date_str: str, time_slot: str, token_number: str, room_number: str = "OPD Room 101") -> dict:
        """Dispatches appointment confirmation with token badge and room details"""
        subject = f"✅ Appointment Confirmed • Token #{token_number} with Dr. {doctor_name}"

        text_content = f"""Hello {patient_name},

Your medical consultation appointment has been successfully confirmed.

APPOINTMENT DETAILS:
- Patient: {patient_name}
- Token Number: #{token_number}
- Doctor: Dr. {doctor_name} ({specialty})
- Hospital / Center: {hospital_name}
- Date: {date_str}
- Preferred Time Slot: {time_slot}
- Room: {room_number}

ARRIVAL INSTRUCTIONS:
Please arrive 15 minutes before your scheduled slot. Scan your digital QR pass at the entrance kiosk or check in at the reception desk to activate your token in the live queue.

CareLink Kerala Network Desk
"""

        html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f1f5f9; margin: 0; padding: 24px; }}
  .card {{ max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); border: 1px solid #e2e8f0; }}
  .header {{ background: linear-gradient(135deg, #0284c7, #0369a1); padding: 24px; text-align: center; color: #ffffff; }}
  .token-badge {{ background: #ffffff; color: #0284c7; font-size: 28px; font-weight: 800; padding: 8px 24px; border-radius: 12px; display: inline-block; margin-top: 12px; }}
  .body {{ padding: 28px; }}
  .row {{ display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #f1f5f9; font-size: 13px; }}
  .label {{ color: #64748b; }}
  .val {{ font-weight: 600; color: #0f172a; text-align: right; }}
  .instructions {{ background: #eff6ff; border-radius: 10px; padding: 14px; margin-top: 20px; font-size: 12px; color: #1e40af; }}
  .footer {{ background: #f8fafc; padding: 16px; text-align: center; font-size: 11px; color: #94a3b8; }}
</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h2 style="margin:0; font-size: 20px;">🏥 Appointment Confirmed</h2>
      <div class="token-badge">Token #{token_number}</div>
    </div>
    <div class="body">
      <p style="font-size: 14px; margin-top:0;">Dear <strong>{patient_name}</strong>,<br>Your consultation appointment is scheduled as follows:</p>
      
      <div style="margin: 16px 0;">
        <div class="row"><span class="label">Doctor:</span><span class="val">Dr. {doctor_name}</span></div>
        <div class="row"><span class="label">Specialty:</span><span class="val">{specialty}</span></div>
        <div class="row"><span class="label">Hospital / Center:</span><span class="val">{hospital_name}</span></div>
        <div class="row"><span class="label">Scheduled Date:</span><span class="val">{date_str}</span></div>
        <div class="row"><span class="label">Time Slot:</span><span class="val">{time_slot}</span></div>
        <div class="row"><span class="label">Consultation Room:</span><span class="val">{room_number}</span></div>
      </div>

      <div class="instructions">
        💡 <strong>Kiosk Arrival Instructions:</strong> Please scan your CareLink Kerala QR pass at the entrance kiosk or report to the reception desk 15 minutes prior to activate your token in the live doctor queue.
      </div>
    </div>
    <div class="footer">
      CareLink Kerala Digital Health Infrastructure • Government of Kerala
    </div>
  </div>
</body>
</html>"""

        return cls._dispatch(subject, text_content, html_content, recipient_email)

    @classmethod
    def send_donation_receipt_email(cls, recipient_email: str, donor_name: str, amount: float, transaction_id: str, campaign_title: str, hospital_name: str) -> dict:
        """Dispatches formal donation receipt with 80G tax exemption note"""
        subject = f"🙏 Tax Exemption Receipt • CareLink Kerala (₹{amount:,.2f})"

        text_content = f"""Dear {donor_name},

Thank you for your generous contribution to CareLink Kerala!

DONATION RECEIPT:
- Receipt Number: REC-{transaction_id[-8:].upper()}
- Payment Ref (Razorpay): {transaction_id}
- Contributed Amount: ₹{amount:,.2f}
- Campaign / Treatment: {campaign_title}
- Cooperating Trust: {hospital_name}
- Date: {timezone.now().strftime('%d %B %Y')}

TAX BENEFIT NOTE:
Donations are eligible for tax deduction under Section 80G of the Income Tax Act. 

Thank you for bringing hope and comfort to palliative patients across Kerala.

Warm regards,
CareLink Kerala Finance & Escrow Desk
"""

        html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; background-color: #f1f5f9; padding: 24px; }}
  .card {{ max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #e2e8f0; }}
  .header {{ background: linear-gradient(135deg, #059669, #047857); padding: 24px; text-align: center; color: #ffffff; }}
  .body {{ padding: 28px; }}
  .receipt-box {{ background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 18px; margin: 16px 0; }}
  .tax-note {{ background: #ecfdf5; border: 1px solid #a7f3d0; padding: 12px; border-radius: 8px; font-size: 12px; color: #065f46; }}
  .footer {{ background: #f8fafc; padding: 16px; text-align: center; font-size: 11px; color: #94a3b8; }}
</style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h2 style="margin:0;">🙏 Donation Receipt</h2>
      <p style="margin:4px 0 0 0; opacity: 0.9;">CareLink Kerala Palliative Trust Escrow</p>
    </div>
    <div class="body">
      <p>Dear <strong>{donor_name}</strong>,<br>We gratefully acknowledge receipt of your donation supporting <strong>{campaign_title}</strong>.</p>
      
      <div class="receipt-box">
        <div style="font-size: 24px; font-weight: 800; color: #059669; margin-bottom: 12px;">₹{amount:,.2f}</div>
        <div style="font-size: 12px; color: #64748b; line-height: 1.6;">
          <strong>Transaction ID:</strong> {transaction_id}<br>
          <strong>Cooperating Org:</strong> {hospital_name}<br>
          <strong>Date:</strong> {timezone.now().strftime('%d %B %Y, %I:%M %p')}
        </div>
      </div>

      <div class="tax-note">
        📜 <strong>80G Tax Exemption Note:</strong> This electronic receipt is valid for tax deduction claims under Section 80G of the Income Tax Act.
      </div>
    </div>
    <div class="footer">
      CareLink Kerala • Empowering Palliative & Critical Healthcare
    </div>
  </div>
</body>
</html>"""

        return cls._dispatch(subject, text_content, html_content, recipient_email)

    @classmethod
    def send_test_email(cls, recipient_email: str) -> dict:
        """Diagnostic utility to verify live SMTP transport connectivity"""
        subject = "🧪 CareLink Kerala — Live SMTP Diagnostic Test"
        text_content = f"Diagnostic test sent at {timezone.now().isoformat()}. If you are reading this in your email inbox, CareLink Kerala SMTP transport is 100% active and working!"
        html_content = f"""<div style="font-family: sans-serif; padding: 24px; background: #f8fafc;">
          <div style="max-width: 500px; margin: 0 auto; background: #ffffff; padding: 24px; border-radius: 12px; border: 1px solid #cbd5e1;">
            <h2 style="color: #059669; margin-top: 0;">✅ SMTP Transport Connected!</h2>
            <p>This is a live diagnostic message from <strong>CareLink Kerala</strong>.</p>
            <p><strong>Timestamp:</strong> {timezone.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
            <p style="font-size: 12px; color: #64748b;">Your Django SMTP settings are active and ready to deliver real OTPs, appointment passes, and receipts directly to user inboxes.</p>
          </div>
        </div>"""
        return cls._dispatch(subject, text_content, html_content, recipient_email)
