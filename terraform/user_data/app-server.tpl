#cloud-config
repo_update: true
repo_upgrade: all

write_files:
  - content: |
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAyZjT0WieumgOoOJgOboJCgPzGUpXRHPfQ3fMAqsq/M3EM1u32NTUDRHporF46shXm4sz4CDXIltNOk08SUcnDwPnTIU+x8nsDnDOE4OaGBThmXa1vATR2/EANmESH5Y1mfYdxr0fUdvb8q93gGx/tMyAe7H6Y6PVoYXh9uUxMZ8o9vjleT875T+AtILBdLdJ/K1pHCqa6+xF6sTUnbyyY4qrkbiYuDIKj3F7DJ3hgKeeNT00XRpGIbuAKEZpMjsnV8TMYT2swJF6jMSQpy5ZYqtogsCmqt1TwPJ0TSejb9knC+zq3wRHigBYS2wvOaZ/nNjG3/Db60U+2w6TM1VGLtFooz2BnaQe9G8JgT0GuCVguMsiYoEBXrDAn+mQ8iEXZQfDes+hoxUsAFN8zAtqqR70A4tlAqUWT+zI4WXOn612IXdLo+v5R/E+E7qgwlvfM5J7ybT5Kx+eUq11yqinfVc6NhWErHNqCtmScRhJHrzwVOFBI+IUr6ZklhB5p4gM/qvb5vfWhS7bi439ihSpBVdU3BxcuP8XMlelr/nC7hB4V05Tdc4RfQ4NzKaxwwFFZwLhBn4ANxurtZIkX3IUn+aj0b3BLQeB5SLZWai04H89R4Q9/21f0007ZBFTsGm1qitAtBJI9miOWT7VGj3SCG4hXBwUKO8IvNPkMjrr1Q== cloud-security
    path: /home/ubuntu/ssh/authorized_keys
  - content: |
      <VirtualHost *:80>
        ServerAdmin webmaster@cloud-security.jbc.dev
        ServerName www.cloud-security.jbc.dev
        ServerAlias cloud-security.jbc.dev
        ErrorLog /var/www/cloud-security.jbc.dev/logs/error.log
        CustomLog /var/www/cloud-security.jbc.dev/logs/access.log combined

        WSGIDaemonProcess helloworldapp user=www-data group=www-data threads=5
        WSGIProcessGroup helloworldapp
        WSGIScriptAlias / /var/www/FLASKAPPS/helloworldapp/helloworldapp.wsgi
        Alias /static/ /var/www/FLASKAPPS/helloworldapp/static
        <Directory /var/www/FLASKAPPS/helloworldapp/static>
            Order allow,deny
            Allow from all
        </Directory>
      </VirtualHost>
  - content: |
      #!/app/.venv/bin/python3
      import sys
      sys.path.insert(0,"/app/2022-cloud-security/flask-app/")
      from flask-app import app as application
runcmd:
 - apt-get update
 - apt-get install apache2 libapache2-mod-wsgi python3-dev git python3
 - a2enmod wsgi
 - mkdir /app
 - git clone https://github.com/joelbcastillo/2022-cloud-security/ /app
 - sudo python3 -m venv /app/.venv
 - source virtualenv /app/.venv/bin/activate && pip install -r /app/2022-cloud-security/flask-app/requirements.txt
 - a2ensite api.conf
 - mkdir -p /var/www/cloud-security.jbc.dev/logs
 - chown -R www-data:www-data cloud-security.jbc.dev
 - /etc/init.d/apach2 reload
