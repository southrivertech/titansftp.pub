# <img src="https://southrivertech.com/software/nextgen/cornerstone/cornerstone48.png" alt="Cornerstone Server logo"> Cornerstone Server - Linux Cloud Edition

Thank you for choosing Cornerstone Server - Cloud Edition from South River Technologies. This is the Pay-as-you-go version of our solution, meaning that it will run fully featured without the need to purchase a license from South River Technologies. Simply fire up your Cornerstone Server VM, and run your business.

## What's on the VM?

This Titan FTP Server Virtual Machine (VM) contains a pre-built and pre-configured installation of the product. 

## Features of Titan FTP Server

Cornerstone is a reverse proxy server that provides perimeter security for your Cornerstone implementation. Enabling you to close ports on your firewall, Cornerstone dynamically opens outbound ports to communicate with Cornerstone. User requests are sent by the Cornerstone server to Cornerstone as a response on the dynamically opened channel. Working exclusively as a passthrough, no data is ever stored on or outside your firewall.

## Getting Started

To launch the Cornerstone Administrator UI point your browser to your VM's public url or IP address. The first time you run the Administrator it will prompt you to create a new Administrator account to allow configuring the Cornerstone server. 

## Configure Cornerstone for External access

The Cornerstone Server instance has been preconfigured for access from an external Cornerstone server via port 45100. The public ports that Cornerstone will proxy to the Cornerstone Server will configured on your Cornerstone server but you will need to make sure the cloud provider firewall will allow those external ports through. For example, the Cornerstone server may wish for the Cornerstone server to publicly listen on port 2200 for SFTP connections. In this case you will need to configure the cloud provider to allow inbound connections on port 2200 as well as the cloud provider firewall settings.

- `Port Setup` - Cornerstone services are running behind both a Windows Firewall and the main Azure/AWS firewall. Your cloud provider will issue a public IP address, or DNS name, for your VM. In order for Cornerstone services to function properly, Cornerstone must be configured with the External IP address of the router/firewall.

- `Private IP Address` - set this to the desired listening IP address where Cornerstone will connect to the Cornerstone server.

- `Public IP Address` - set this to the desired public IP address issued by your cloud provider for external connections to be proxied to the Cornerstone server.
- 



## Tech Support

Complimentary technical support is available on our website at https://www.srthelpdesk.com

## More Information

## WebSite(s)

Cornerstone Server micro site: [https://www.cornerstonemft.com](https://www.cornerstonemft.com)

South River Technologies corporate WebSite:  [https://www.SouthRiverTechnologies.com](https://www.SouthRiverTechnologies.com)




