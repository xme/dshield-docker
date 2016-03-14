DShield Docker
==============

This Docker container starts a SSH honeypot (based on Cowrie[1]) and enables the DShield output module to report statistics to the SANS ISC DShield project. This project is based on Johannes Ulrich's Raspberry Pi sensor project[2].

[1] https://github.com/micheloosterhof/cowrie
[2] https://github.com/DShield-ISC/dshield


# Building the image:

```
# git clone https://github.com/xme/dshield-docker
# cd dshield-docker
# docker build -t dshield/honeypot .
```

# Running the image

First, create a configuration file which will contain your DShield account details:
```
# cat env.txt
DSHIELD_UID=xxxxxxxxxx
DSHIELD_APIKEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
DSHIELD_EMAIL=xxxxxxxxxxxxxxxxxxx
``` 
Your credentials will be validated and the honeyport properly configured.
Don't forget to register[1] if you don't already have an account.

[1] https://www.dshield.org/register.html

Boot the container:
```
# docker run -d -p 2222:2222 --env-file=env.txt --restart=always --name dshield dshield/honeypot
b56e526b6f7c9b6cb419245757b0586f73d7e99089fa93409f3626122990505a
# docker logs dshield
Validating provided credentials...
API key verification succeeded!
Starting cowrie...
# 
```
The honeypot is listening to port TCP/2222. The parameter '-p 2222:2222' used to run the container allows you to still access the Docker server on port 22. Be sure to redirect your malicious SSH traffic to the port 2222 at your firewall.

# Post-boot steps

Once the container started, connect to it:
```
# docker exec -it dshield bash
```
The honeypot is installed in /src/cowrie/. You can track data report to DShield by looking for the following events in log/cowrie.log:
```
2016-03-14 21:32:59+0100 [-] dshield SUCCESS: Sent 52 bytes worth of data to secure.dshield.org
```

# Todo

- Implement more reporting
- Automatic log rotation
- Data persistence
