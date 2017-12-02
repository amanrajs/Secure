import os, time, smtplib

from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

path_to_watch = "C:\Users\Public\Videos"
print "watching: " + path_to_watch
before = dict ([(f, None) for f in os.listdir (path_to_watch)])
while 1:
    after = dict ([(f, None) for f in os.listdir (path_to_watch)])
    added = [f for f in after if not f in before]
    removed = [f for f in before if not f in after]
    if removed: print "Removed: ", ", ".join (removed)
    if added:
        print "Added: ", ", ".join (added)
        me = "OUR-EMAIL"
        you = "CLIENTS"
        msg = MIMEMultipart()
        msg['Subject'] = "A stranger is in your house"
        msg['From'] = me
        msg['To'] = you
        body = "plese see the image attached of stranger"
        msg.attach(MIMEText(body,'plain'))

        file="DIR/f"
        attachment=open("directory","rb")
        attachment.close()
        
        part=MIMEBase('application','octet-stream')
        part.set_payload((attachment).read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition', "attachment;filename=%s"%filename)

        msg.attach(part)
        
        s = smtplib.SMTP('smtp.gmail.com',587)
        s.starttls()
        s.login("email","passwd")
        text=msg.as_string()
        s.sendmail(me, you,text)
        s.quit()
print ("exit")
