# CreateClusteredAppEnvironment.ps1

## The following will be done and in order

2 nodes will be hardened using INFOSEC production PSAPI
The Failover Cluster Manager will be installed on both nodes
Cluster ip will be determined and registered in IPAM
The first node will create the cluster (CNO will be created by this event)
The VCO will be created in Active Directory
The VCO security attributes will be changed to allow the CNO priveleges

## Getting Started

Download the script to your machine to execute

### Prerequisites

From your laptop, you will need to open a powershell session, under a user context that has administrative access on the target nodes which will be joined as a cluster, or else the script will fail.

- You will need to install Failover Clustering tools (including the management tools) on both servers, restart the servers and go into server manager to ensure it is installed before running the script
- Ensure that the servers which will form part of the cluster, are configured with the correct DNS settings


##### Please note the following

+ The following parameters will be required when executing the scripts
# First node name (not FQDN)
# Second node name (not FQDN)
# CNO (Cluster named object)
- Please note that the CNO should not exceed 15 characters. Script execution will stop if it is spesified otherwise.
# VCO (Virtual cluster object)
- Please note that the VCO should not exceed 15 characters. Script execution will stop if it is spesified otherwise.
# SDLC
- DEV/INT/QA/PRD
# Location
- NP/PRD
# The password for the SecurityServices account to retrieve token from IDP (FLEXWALLET)
# VMM Action account password for the Location you have specified
# Production Scorch account password