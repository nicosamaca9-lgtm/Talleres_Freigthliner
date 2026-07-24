import httpx

from app.core.config import settings

RESEND_API_KEY = settings.RESEND_API_KEY or ''
BASE_URL = settings.BASE_URL or 'https://thorough-manifestation-production-a72f.up.railway.app'
FROM_EMAIL = 'TF Centro Automotriz <onboarding@resend.dev>'


def _send_via_resend(to_email: str, subject: str, html_content: str):
    """Envía un correo usando la API HTTP de Resend (funciona en Railway sin restricciones de SMTP)."""
    if not RESEND_API_KEY:
        print('[EmailService] No hay RESEND_API_KEY configurada.')
        return

    try:
        response = httpx.post(
            'https://api.resend.com/emails',
            headers={
                'Authorization': f'Bearer {RESEND_API_KEY}',
                'Content-Type': 'application/json',
            },
            json={
                'from': FROM_EMAIL,
                'to': [to_email],
                'subject': subject,
                'html': html_content,
            },
            timeout=10,
        )
        if response.status_code not in (200, 201):
            print(f'[EmailService] Error de Resend ({response.status_code}): {response.text}')
        else:
            print(f'[EmailService] Correo enviado correctamente a {to_email}')
    except Exception as e:
        print(f'[EmailService] Error al enviar correo a {to_email}: {e}')
        raise


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

    _send_via_resend(
        to_email=correo_destinatario,
        subject='Activa tu cuenta en TF Centro Automotriz',
        html_content=html_content,
    )


def send_password_recovery_email(to_email: str, pin: str):
    """Envía un correo con el PIN de 6 dígitos para recuperar contraseña."""
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

    _send_via_resend(
        to_email=to_email,
        subject='Recuperación de Contraseña - Talleres Freightliner',
        html_content=html_content,
    )
