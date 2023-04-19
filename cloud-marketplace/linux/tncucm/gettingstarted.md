# Titan SFTP Server - CUCM Linux Cloud Edition

Thank you for choosing Titan SFTP Server - CUCM Edition from South River Technologies. This is the Pay-as-you-go version of our solution, meaning that it will run fully featured without the need to purchase a license from South River Technologies. Simply fire up your Titan SFTP Server VM, configure your Cisco® backup systems to point out to your Titan SFTP Server, and run your business using a Cisco recommended and Cisco Certified Backup Server

## What's on the VM?

This Titan SFTP Server Virtual Machine (VM) contains a pre-built and pre-configured installation of the product. All bells and whistles are available for you to utilize and a sample server instance called Default Server has already been configured with SFTP services enabled. There is also a test user for logging in to the system. NOTE: It is strongly recommended that you change the credentials of the test user immediately.

## Features Titan SFTP Server

Some of the features of Titan which are available include:

- `SFTP`- currently running on port 2200 and includes all strong encryption cyphers and both password and public key authentication are enabled and supported. Putty's command line PSFTP.exe utility is included in the C:\Program Files\South River Technologies\srxserver\Utils folder and can be used for testing SFTP access. Connecting to the server can be accomplished from the command line using

  > psftp -P 2200 test@localhost -pw test
  >
- `Public Host Key Authentication`- SSH's highly secure Public Key authentication has been enabled on this server. To use Public Host Key authentication, upload your SFTP client Public Key (.pub) file to the Titan Server and use the Host Key Management utility to Import the client Public Key into the Titan Server Admin console. Once the client's public key has been imported into the Admin console, simply locate the user's account information under the Users node and on their SFTP tab, assign the key to their account. If you have trouble with this feature, contact our help desk and we’ll be glad to help you get started
- `Email Notifications`- Titan has a full Events Management system which can be leveraged to do many things, including send email notifications for alerts. To fully leverage the power of Email Notifications, please make sure to configure the settings for your specific email server under the Titan Admin console's Email tab.
- Many more features are available, see the Titan Admin Users Guide from the Help menu in the Admin Console.

## Getting Started

To launch the Titan SFTP Administrator UI point your browser to your VM's public url or IP address and use port 41443, e.g. https://yourdomain.com:41443 The WebUI is using a non-CA validated test certificate. While you will be able to connect on port 41443, you will get warning about the invalid certificate. This it completely normal and will go away when you replace your test certificate with a valid certificate from a CA

The first time you run the Administrator it will prompt you to create a new Administrator account to allow configuring the server.

## Configure Titan for External access

The Test Server instance has been preconfigured for local access. You can access the server using the Localhost, or the VN's IP address. SFTP services are available on port 2200. Once you have performed initial testing using the internal access points and the default 'test' username, you are ready to configure the system for access from the outside.

1. Expand the Titan SFTP Domains node in the tree, and then expand the Default Server Server Instance.
2. Select the Users node from the tree, click the “+” icon on the right hand side to create a new user. Follow the New User Wizard to add a new user to the system.

   > NOTE: once you create a new user, it is recommended that the test user account is disabled and/or deleted for security purposes.
   >
3. Select the Services node located in the tree just below the Default Server node. Along the right side of the screen will be the list of services. Select "SSH/SFTP". Using the Host Key Management utility, create a new distinct host key for your new server. While Titan comes pre-configured with a stock host key, this key is for testing only and should never be used in a production environment. Once you have the new key created, delete the test key.

At this point, the general configurations are complete and the test user should be able to login using any industry standard SFTP client.  Please see the Titan help file for any specific settings/configuration requirements as well as how to use the new server creation wizard to generate a new, customer specific server instance.

## Configuring Cisco CUCM Backup Services

Once you have your Titan SFTP Server – CUCM Edition up and running with a new Server Host Key and a new Titan Username, you are ready to configure your CUCM Backup Service to back your Cisco devices up to the Titan server. 

Backup Device Name – You can set this to anything, we used TitanCUCMBackups

Host name/IP Address – This value will be the public IP address as given out in the Azure/AWS Console.

Path name – this will be the default path on the Titan server to store data. Use a simple period ‘.’ For this value which will tell 
the Titan server to use the default home directory for the data storage.

User name – For our example, we created a user on the Titan server with the username of TitanUser so we specify that username here.

Password – Enter the password for the TitanUser.

Number of backups – You can set this to 2 and run your backups a few times. Once you have a few test backups on the Titan server, check the disk usage. Once you have a ball-park idea of how much storage each backup will use, you can adjust this value up or down based on your needs and storage capabilities.

## Notes

- The test server has a test host key. Don't use these once you open up the server to public access as they are not meant for general use.
- The Firewall has been pre-configured to allow inbound traffic on port 2200 and 41443. This will allow external programs the ability to connect to the Titan server's Default Server instance on port 2200 and Web interface.
- SFTP services are running on port 2200. While this is not an industry standard port for SFTP, our 20+ years of experience has taught us that opening port 22 to the internet immediately invites hundreds of hackers to hammer your server trying to break in. Using a non-standard port will not only thwart hackers but also limit unnecessary traffic and bandwidth usage on your VM. We recommend moving your SFTP server to some non-standard port, such as port 2200. When you change your port in the Titan Admin console on the SFTP tab, you will also need to update the SFTP port on the Windows Firewall and also in the Azure/AWS console. This will ensure that public IP traffic will be successfully routed through the Azure/AWS firewall over to your VM and your local VM's Windows Firewall will pass that same port traffic directly to your Titan Server.

## Tech Support

Complimentary technical support is available on our website at https://helpdesk.titanftp.com (use TitanPAYG as your registration code)

## WebSite(s)

South River Technologies corporate WebSite:  [https://www.SouthRiverTechnologies.com](https://www.SouthRiverTechnologies.com)

Cornerstone MFT (Enterprise grade Managed File Transfer Solution): [https://www.CornerstoneMFT.com](https://www.cornerstonemft.com)

DMZedge Server (Secure reverse proxy server for Cornerstone MFT): [https://www.dmzedge.com](https://www.dmzedge.com)

Titan SFTP Server micro site: [https://www.titanftp.com](https://www.titanftp.com)

WebDrive (Virtual Drive Mapping Client): [https://www.WebDrive.com](https://www.webdrive.com)
