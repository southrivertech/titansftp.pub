# <img src="https://southrivertech.com/software/nextgen/titanftp/titanftp48.png" alt="Titan FTP Server logo"> Titan FTP Server - Cloud Marketplace Repository</img>

This repository contains various documents and utilities for users of our cloud offerings. 

We currently offer our product line on the Amazon AWS Marketplace, Microsoft Azure Marketplace, and Google Cloud Marketplace. On
each Cloud Marketplace, there will be Windows and Linux versions of the products.

## Titan FTP Server - CUCM Edition (tncucm)

The CUCM Edition of Titan has been preconfigured and optimized for use as a secure backup server for CISCO CUCM devices. The CUCM
Edition is listening on port 2200 for UCM backup software and has been hardened and optimized for security and effeciency.

## Titan FTP Server - SFTP Edition (tnsftp)

The SFTP Edition of Titan has been preconfigured and optimized for use purely as an SFTP server. All other protocols and services are 
disabled to ensure the levels of performance, I/O and security. The SFTP server is listening on port 2200 with the default SFTP
version set to Version 4. Weak ciphers have been disabled and public host key support is enabled. A test user account is created
for testing password authentication. For Public key authentication, log in to the Admin console and upload an SSH public key to the
users account.

## Titan FTP Server - Enterprise Edition (tnent)

The Enterprise Edition of Titan been preconfigured with all features enabled (except for non-secure FTP). SFTP services are running
on port 2200, FTP/S services on port 990 with Passive mode ports 50000-50075, and a secure WebUI is available on port 443. As with
all editions of Titan, it has been hardened with all weak security protocols disabled.