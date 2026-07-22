import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.core.config import settings

SMTP_HOST = 'smtp.gmail.com'
SMTP_PORT = 587
SMTP_USER = settings.SMTP_USER or 'serviciostf123@gmail.com'
SMTP_PASSWORD = settings.SMTP_PASSWORD or ''
BASE_URL = settings.BASE_URL or 'http://localhost:8000'


def send_verification_email(correo_destinatario: str, nombre: str, token: str):
    verification_link = f'{BASE_URL}/api/v1/auth/verify-email?token={token}'
    html_content = f'''<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"></head>
<body style="font-family:Arial,sans-serif;background:#f4f4f4;margin:0;padding:20px;">
  <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.1);">
    <div style="background:#1a1a2e;padding:28px 32px;">
      <h1 style="color:#F6C90E;margin:0;font-size:22px;">TF Centro Automotriz</h1>
      <p style="color:#aaa;margin:4px 0 0;font-size:13px;">Verificacion de cuenta</p>
    </div>
    <div style="padding:32px;">
      <p style="font-size:16px;color:#333;">Hola, <strong>{nombre}</strong>.</p>
      <p style="font-size:14px;color:#555;line-height:1.6;">
        Gracias por registrarte en <strong>TF Centro Automotriz</strong>. Para activar tu cuenta
        y poder iniciar sesion, haz clic en el boton de abajo.
      </p>
      <div style="text-align:center;margin:32px 0;">
        <a href="{verification_link}"
           style="background:#F6C90E;color:#1a1a2e;text-decoration:none;padding:14px 32px;border-radius:6px;font-weight:bold;font-size:15px;">
          Activar mi cuenta
        </a>
      </div>
      <p style="font-size:12px;color:#999;line-height:1.6;">
        Si no creaste esta cuenta, ignora este correo.
      </p>
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      <p style="font-size:12px;color:#aaa;text-align:center;">
        &copy; 2025 TF Centro Automotriz &middot; Duitama, Boyaca, Colombia
      </p>
    </div>
  </div>
</body></html>'''

    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'Activa tu cuenta en TF Centro Automotriz'
    msg['From'] = f'TF Centro Automotriz <{SMTP_USER}>'
    msg['To'] = correo_destinatario
    msg.attach(MIMEText(html_content, 'html'))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.ehlo()
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.sendmail(SMTP_USER, correo_destinatario, msg.as_string())
    except Exception as e:
        print(f'[EmailService] Error al enviar correo a {correo_destinatario}: {e}')
        raise

def send_password_recovery_email(to_email: str, pin: str):
    """
    Envía un correo con el PIN de 6 dígitos para recuperar contraseña.
    """
    if not SMTP_PASSWORD or not SMTP_USER:
        print("[EmailService] No hay credenciales SMTP configuradas para recuperación.")
        return

    msg = MIMEMultipart("alternative")
    msg['Subject'] = "Recuperación de Contraseña - Talleres Freightliner"
    msg['From'] = f"Talleres Freightliner <{SMTP_USER}>"
    msg['To'] = to_email

    html_content = f"""
    <html>
    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
        <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
            <h2 style="color: #333333; text-align: center;">Recuperación de Contraseña</h2>
            <p style="color: #555555; font-size: 16px;">Hola,</p>
            <p style="color: #555555; font-size: 16px;">Has solicitado restablecer tu contraseña. Usa el siguiente código de 6 dígitos en la aplicación:</p>
            <div style="text-align: center; margin: 30px 0;">
                <span style="background-color: #2ECC71; color: #ffffff; padding: 15px 30px; font-size: 24px; font-weight: bold; border-radius: 5px; letter-spacing: 5px;">{pin}</span>
            </div>
            <p style="color: #555555; font-size: 16px;">Si no solicitaste este cambio, puedes ignorar este correo de forma segura.</p>
            <p style="color: #777777; font-size: 12px; margin-top: 40px; text-align: center;">
                &copy; 2026 Talleres Freightliner. Todos los derechos reservados.
            </p>
        </div>
    </body>
    </html>
    """

    part = MIMEText(html_content, "html")
    msg.attach(part)

    try:
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USER, SMTP_PASSWORD)
        server.sendmail(SMTP_USER, to_email, msg.as_string())
        server.quit()
    except Exception as e:
        print(f"[EmailService] Error al enviar correo de recuperación a {to_email}: {e}")
        raise
