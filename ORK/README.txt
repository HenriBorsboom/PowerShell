

To complete your customized deployment follow these steps:

1. Open an administrative Windows PowerShell console on the Hyper-V server.

2. If not already done, enable Windows PowerShell scripting on the hypervisor by typing 
   "Set-ExecutionPolicy Unrestricted" and pressing the enter key at the command prompt.

3. From the directory where your scripts are located type ".\ Deploy.ps1" and press the enter key.

4. The scripts will begin executing. Depending on your hardware speed, virtual machine creation can 
   take up to an hour.

5. After the virtual machines are created and Active Directory has been installed, all of the virtual
   machines will be powered on and joined to the domain. You may sign on to the domain controller to view
   the deployment progress.

6. If you run into problems, please see the Troubleshooting section of the Deployment Guide.