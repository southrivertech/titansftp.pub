# <img src="https://southrivertech.com/software/nextgen/Titan FTP/Titan FTP48.png" alt="Titan FTP Server logo"> Titan FTP Server - Linux Cloud Edition

Thank you for choosing Titan FTP Server - Cloud Edition from South River Technologies. This is the Pay-as-you-go version of our solution, meaning that it will run fully featured without the need to purchase a license from South River Technologies. Simply fire up your Titan FTP Server VM, and run your business.

## What's on the VM?

This Titan FTP Server Virtual Machine (VM) contains a pre-built and pre-configured installation of the product. 

## Features of Titan FTP Server

Titan FTP is a reverse proxy server that provides perimeter security for your Titan FTP implementation. Enabling you to close ports on your firewall, Titan FTP dynamically opens outbound ports to communicate with Titan FTP. User requests are sent by the Titan FTP server to Titan FTP as a response on the dynamically opened channel. Working exclusively as a passthrough, no data is ever stored on or outside your firewall.

## Getting Started

To launch the Titan FTP Administrator UI point your browser to your VM's public url or IP address. The first time you run the Administrator it will prompt you to create a new Administrator account to allow configuring the Titan FTP server. 

## Configure Titan FTP for External access

The Titan FTP Server instance has been preconfigured for access from an external Titan FTP server via port 45100. The public ports that Titan FTP will proxy to the Titan FTP Server will configured on your Titan FTP server but you will need to make sure the cloud provider firewall will allow those external ports through. For example, the Titan FTP server may wish for the Titan FTP server to publicly listen on port 2200 for SFTP connections. In this case you will need to configure the cloud provider to allow inbound connections on port 2200 as well as the cloud provider firewall settings.

- `Port Setup` - Titan FTP services are running behind both a Windows Firewall and the main Azure/AWS firewall. Your cloud provider will issue a public IP address, or DNS name, for your VM. In order for Titan FTP services to function properly, Titan FTP must be configured with the External IP address of the router/firewall.

- `Private IP Address` - set this to the desired listening IP address where Titan FTP will connect to the Titan FTP server.

- `Public IP Address` - set this to the desired public IP address issued by your cloud provider for external connections to be proxied to the Titan FTP server.
- 



## Tech Support

 [https://www.srthelpdesk.com](https://www.srthelpdesk.com)


## WebSite(s)

Titan FTP Server micro site: [https://www.Titan FTPmft.com](https://www.Titan FTPmft.com)

South River Technologies corporate WebSite:  [https://www.SouthRiverTechnologies.com](https://www.SouthRiverTechnologies.com)




