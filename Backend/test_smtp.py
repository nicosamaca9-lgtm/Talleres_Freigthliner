import smtplib

try:
    server = smtplib.SMTP('smtp.gmail.com', 587)
    server.ehlo()
    server.starttls()
    server.login('serviciostf123@gmail.com', 'obgeqkprhwghmwms')
    print('LOGIN SUCCESS')
    server.quit()
except Exception as e:
    print(f'LOGIN FAILED: {e}')
