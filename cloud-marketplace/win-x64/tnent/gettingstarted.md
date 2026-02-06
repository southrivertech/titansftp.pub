# <img src="https://srtcdnstorage.blob.core.windows.net/software/nextgen/titansftp/titansftp48.png" alt="Titan logo"> Titan SFTP Server - Enterprise Cloud Edition for Windows</img>

Thank you for choosing Titan SFTP Server from South River Technologies. This is the Pay-as-you-go version of our solution.

## What's on the VM?

This Titan SFTP Server Virtual Machine (VM) contains a pre-built and pre-configured installation of the product. A sample server instance called Default Server has already been configured with FTP/S, SFTP services enabled. There is also a test user for logging in to the system however the user account is disabled by default so you will need to edit the user and enable the account before you can login. NOTE: It is strongly recommended that you change the credentials of the test user immediately.

## Getting Started

To launch the Titan SFTP Administrator click on the Titan SFTP Server desktop icon which will launch the browser and connect to the default localhost admin port of 31443. The first time you run the Administrator it will prompt you to create a new Administrator account to allow configuring the server.

## Features Titan SFTP Server

Some of the features of Titan which are available include:

- `Implicit FTP/S`– Implicit FTP/S is running on port 990. Connect on port 990 with your FTP client in Implicit mode and the security is immediate.
- `HTTP/S`– The optional secure WebUI is running on port 443 and is using a non-CA validated test certificate. While you will be able to connect on port 443, you will get warning about the invalid certificate. This it completely normal and will go away when you replace your test certificate with a valid certificate from a CA. To test, point your browser to https://localhost/ for the logon page
- `SFTP`- currently running on port 2200 and includes all strong encryption cyphers and both password and public key authentication are enabled and supported. Putty's command line PSFTP.exe utility is included in the C:\Program Files\South River Technologies\srxserver\Utils folder and can be used for testing SFTP access. Connecting to the server can be accomplished from the command line using

  > psftp -P 2200 test@localhost -pw test
  >
- `Public Host Key Authentication`- SSH's highly secure Public Key authentication has been enabled on this server. To use Public Host Key authentication, upload your SFTP client Public Key (.pub) file to the Titan Server and use the Host Key Management utility to Import the client Public Key into the Titan Server Admin console. Once the client's public key has been imported into the Admin console, simply locate the user's account information under the Users node and on their SFTP tab, assign the key to their account. If you have trouble with this feature, contact our help desk and we’ll be glad to help you get started
- `Email Notifications`- Titan has a full Events Management system which can be leveraged to do many things, including send email notifications for alerts. To fully leverage the power of Email Notifications, please make sure to configure the settings for your specific email server under the Titan Admin console's Email tab.

## Optional Feature Modules for Titan SFTP

Some optional advanced features of Titan SFTP require a seperate module license available for purchase from South River Technologies

1. Web UI & File Sharing - An end user web browser interface to access files, easy link sharing for internal and external partners, DropZone portals for secure file uploads from external partners
2. Advanced Authentication (MFA) - Supported verification methods include email codes, SMS text codes, Microsoft Authenticator, and Google Authenticator.
3. FIPS Compliance - FIPS 140-2 validated cryptographic controls enforced across all supported Titan products.
4. Advanced Encryption (PGP) - Open PGP-compliant streaming PGP encryption and file-at-rest encryption, automated decryption, and comprehensive partner key management.
5. High Availability & Scaling - Clustering, failover protection, load distribution, and enterprise-grade resilience for large-scale deployments.
6. Neo AI Assitant - AI-powered operational insights, anomaly detection, predictive analytics, and intelligent configuration guidance.

For more information on Titan Modules please visit: [https://southrivertech.com/titan-add-on-modules](https://southrivertech.com/titan-add-on-modules/)

## Configure Titan for External access

The Test Server instance has been preconfigured for local access. You can access the server using the Localhost, internal IP address, or Windows PC name. SFTP services are available on port 2200. Once you have performed initial testing using the internal access points and the default 'test' username, you are ready to configure the system for access from the outside.

1. Expand the Titan SFTP Domains node in the tree, and then expand the Default Server Server Instance.
2. Select the Users node from the tree, click the “+” icon on the right hand side to create a new user. Follow the New User Wizard to add a new user to the system.

   > NOTE: once you create a new user, it is recommended that the test user account is disabled and/or deleted for security purposes.
   >
3. Select the Services node located in the tree just below the Default Server node. Along the right side of the screen will be the list of services. Select "SSH/SFTP". Using the Host Key Management utility, create a new distinct host key for your new server. While Titan comes pre-configured with a stock host key, this key is for testing only and should never be used in a production environment. Once you have the new key created, delete the test key.
4. FTP Setup – Titan’s FTP services are running behind both a Windows Firewall and the main Azure/AWS firewall. Your cloud provider will issue a public IP address, or DNS name, for your VM. In order for FTP services to function properly, Titan must be configured with the External IP address of the router/firewall. This value is set on the Server Advanced tab under the Default Server node in the Titan Admin Console. Replace the placeholder value of 1.2.3.4 with your valid IP address.

At this point, the general configurations are complete and the test user should be able to login using any industry standard SFTP client.  Please see the Titan help file for any specific settings/configuration requirements as well as how to use the new server creation wizard to generate a new, customer specific server instance.

## Notes

- `HTTP/S and FTP/S Services` – The optional end user web UI server has been tested against both the DigiCert.com and SslLabs.com TLS security vulnerability scanner and passed. This Windows Server image has been hardened with 3DES, SHA1, TLS 1.0 and other weak ciphers being disabled.
- `FTP/S Services` - The default security mode for the data connection is PROT P. This means that if your FTP/S client does not specify PROT P or PROT C before opening a data connection, PROT P is assumed and the server will expect the client to perform a secure handshake during the transfer
- The test server has a test host key. Don't use these once you open up the server to public access as they are not meant for general use.
- The Firewall has been pre-configured to allow inbound traffic on port 2200, 990, 443, and FTP Passive range 50000-50100. This will allow external programs the ability to connect to the Titan server's Default Server instance on port 2200 and via FTP and Web interface.
- SFTP services are running on port 2200. While this is not an industry standard port for SFTP, our 20+ years of experience has taught us that opening port 22 to the internet immediately invites hundreds of hackers to hammer your server trying to break in. Using a non-standard port will not only thwart hackers but also limit unnecessary traffic and bandwidth usage on your VM. We recommend moving your SFTP server to some non-standard port, such as port 2200. When you change your port in the Titan Admin console on the SFTP tab, you will also need to update the SFTP port on the Windows Firewall and also in the Azure/AWS console. This will ensure that public IP traffic will be successfully routed through the Azure/AWS firewall over to your VM and your local VM's Windows Firewall will pass that same port traffic directly to your Titan Server.
- /datadisk is a 512GB data disk configured to store your Titan user data. If you need to add more storage to your server, see the
  Azure/AWS portal documentation for more information about adding new volumes/drives.
- /logdisk is a 74GB disk configured to store server logs

## Tech Support

Complimentary technical support is available on our website at https://helpdesk.titanftp.com (use TitanPAYG as your registration code)

## WebSite(s)

South River Technologies corporate WebSite:  [https://www.southrivertech.com](https://www.southrivertech.com)<br />
Titan MFT (Enterprise grade Managed File Transfer Solution): [https://www.TitanMFT.com](https://www.TitanMFT.com)<br />
Titan DMZ Server (Secure reverse proxy server for Titan MFT): [https://www.TitanDMZ.com](https://www.TitanDMZ.com)<br />
Titan SFTP Server micro site: [https://www.TitanFTP.com](https://www.TitanFTP.com)<br />
WebDrive (Virtual Drive Mapping Client): [https://www.WebDrive.com](https://www.webdrive.com)<br />





