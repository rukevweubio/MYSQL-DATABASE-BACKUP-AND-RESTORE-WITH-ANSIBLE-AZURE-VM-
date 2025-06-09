###  MySQL Provisioning and Backup Automation on Azure
## Project Overview
Objective
The primary objective of this project is to automate the provisioning, configuration, and backup of a MySQL database hosted on an Azure Virtual Machine (VM) using Ansible. The project aims to:
- Deploy a MySQL server on an Azure VM with secure configurations.
- Create database tables to support application data storage.
- Implement a reliable backup mechanism using mysqldump to ensure data integrity and recovery.
- Automate periodic backups using cron jobs and securely store backups in an Azure Blob Storage account.
- Ensure scalability, security, and efficiency in database management and disaster recovery processes.

## Problem Statement
Organizations relying on MySQL databases for critical applications face challenges in:
- Manual Provisioning: Setting up MySQL on cloud VMs is time-consuming and prone to configuration errors.
- Data Loss Risk: Without automated backups, there is a significant risk of data loss due to hardware failures, human errors, or cyberattacks.
- Backup Management: Manual backup processes are inefficient and unreliable, especially for large-scale databases.
- Storage Scalability: Local storage for backups is limited, and managing backups in a secure, scalable cloud storage solution is often complex.
- Consistency: Ensuring consistent database configurations across environments is challenging without automation.


## Solution
- The proposed solution automates the entire lifecycle of MySQL database management on an Azure VM:
- Automated Provisioning: Ansible playbooks are used to deploy and configure MySQL on an Azure VM, ensuring consistent and secure setups.
- Database Setup: Scripts create necessary tables to support application requirements.
- Backup Automation: mysqldump generates database backups, which are scheduled via cron jobs for regular execution.
- Cloud Storage Integration: Backups are securely uploaded to an Azure Blob Storage account for scalable, durable storage.
- Disaster Recovery: The solution ensures that backups are readily available for restoration, minimizing downtime in case of failures.

## Tools and Technologies Used
### The project leverages the following tools and technologies:
- Ansible: For automating the provisioning and configuration of the MySQL server on the Azure VM.
- MySQL: The relational database management system used for data storage.
- Azure Virtual Machine: The cloud-based server hosting the MySQL database.
- Azure Blob Storage: A scalable, secure storage service for storing database backups.
- mysqldump: A MySQL utility for creating logical backups of the database.
- Cron: A Linux utility for scheduling automated backup tasks.
- Azure CLI: For managing Azure resources, including storage accounts and blob uploads.
- Python: Used for scripting and interacting with Azure services (via Azure SDK).
- Ubuntu: The operating system running on the Azure VM (Ubuntu 20.04 LTS).
- Git: For version control of Ansible playbooks and scripts.

## Project Implementation
1. Prerequisites
Before implementing the solution, the following prerequisites were ensured:
- An active Azure subscription with permissions to create VMs and storage accounts.
- Ansible installed on a control node (local machine or a dedicated server).
- SSH access configured for the Azure VM.
- Azure CLI installed and authenticated on the control node.
- A Git repository for storing Ansible playbooks and scripts.

2. Azure VM Setup
- An Azure VM was created with the following specifications:
- OS: Ubuntu 20.04 LTS
- Size: Standard_D2s_v3 (2 vCPUs, 8 GB RAM)
- Networking: Public IP address with SSH (port 22) and MySQL (port 3306) ports open in the Network Security Group (NSG).
- Storage: 30 GB SSD for the OS disk.
![CREATE AZURE VM](https://github.com/rukevweubio/MYSQL-DATABASE-BACKUP-AND-RESTORE-WITH-ANSIBLE-AZURE-VM-/blob/master/Screenshot%20(1052).png)


## ANSIBLE INSTALLATION
- Install MySQL Server and Client.
- Secure the MySQL installation (e.g., set root password, remove anonymous users).
- Create a database and user for the application.
- Create tables within the database.

Sample Ansible Playbook
```
---
- name: Provision MySQL on Azure VM
  hosts: EC2
  become: yes
  vars:
    mysql_root_password: "{{ vault_mysql_root_password }}"
    db_name: app_db
    db_user: app_user
    db_password: "{{ vault_db_password }}"
  tasks:
    - name: Install MySQL Server and Client
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - mysql-server
        - mysql-client
        - python3-pymysql

    - name: Start and enable MySQL service
      service:
        name: mysql
        state: started
        enabled: yes

    - name: Set MySQL root password
      mysql_user:
        name: root
        host: localhost
        password: "{{ mysql_root_password }}"
        login_unix_socket: /var/run/mysqld/mysqld.sock
        state: present

    - name: Remove anonymous users
      mysql_user:
        name: ''
        host_all: yes
        state: absent
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create application database
      mysql_db:
        name: "{{ db_name }}"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Create application user
      mysql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}.*:ALL"
        state: present
        login_user: root
        login_password: "{{ mysql_root_password }}"

    - name: Copy table creation script
      copy:
        src: files/create_tables.sql
        dest: /tmp/create_tables.sql

    - name: Execute table creation script
      mysql_db:
        name: "{{ db_name }}"
        state: import
        target: /tmp/create_tables.sql
        login_user: root
        login_password: "{{ mysql_root_password }}"

Table Creation Script (create_tables.sql):
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

Sensitive data (e.g., mysql_root_password, db_password) were stored in Ansible Vault for encryption.
4. Database Backup with mysqldump
A shell script was created to back up the database using mysqldump:
#!/bin/bash
BACKUP_DIR="/var/backups/mysql"
DB_NAME="app_db"
DB_USER="root"
DB_PASS="your-root-password"
TIMESTAMP=$(date +%F_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$TIMESTAMP.sql"

mkdir -p $BACKUP_DIR
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_FILE
gzip $BACKUP_FILE
```
The script:

Creates a timestamped SQL dump of the database.
Compresses the dump using gzip to save space.
Stores backups in /var/backups/mysql.

### Cron Job for Backup Automation
A cron job was configured to run the backup and upload scripts daily at 2 AM:
0 2 * * * /bin/bash /scripts/backup_mysql.sh && /usr/bin/python3 /scripts/upload_to_azure.py
The cron job was added using crontab -e on the VM.
![CROTABLE BACKUP](https://github.com/rukevweubio/MYSQL-DATABASE-BACKUP-AND-RESTORE-WITH-ANSIBLE-AZURE-VM-/blob/master/Screenshot%20(1051).png)
### Testing and Validation
- Provisioning: Verified that Ansible playbooks successfully installed and configured MySQL, created the database, and set up tables.
- Backups: Confirmed that mysqldump generated valid SQL dumps and that backups were compressed.
- Uploads: Ensured backups were successfully uploaded to Azure Blob Storage.
- Cron: Tested the cron job by manually triggering it and checking for new blobs in Azure.
- Restoration: Restored a backup to a test database to validate data integrity.

## Challenges Encountered
The project faced several challenges, along with their resolutions:
Ansible MySQL Module Issues:
Challenge: The mysql_user module failed due to missing python3-pymysql on the target VM.
Resolution: Added a task to install python3-pymysql before running MySQL-related tasks.


### Azure NSG Configuration:
- Challenge: MySQL port 3306 was initially inaccessible due to restrictive NSG rules.
- Resolution: Updated the NSG to allow inbound traffic on port 3306 from trusted IPs.
![AZURE CLOUD](https://github.com/rukevweubio/MYSQL-DATABASE-BACKUP-AND-RESTORE-WITH-ANSIBLE-AZURE-VM-/blob/master/Screenshot%20(1045).png)
### Cron Job Failures:
- Challenge: The cron job failed due to incorrect script permissions and missing environment variables.
- Resolution: Set executable permissions (chmod +x) on scripts and added environment variables to the cron script.


## Azure Storage Authentication:
- Challenge: Uploading to Blob Storage failed due to an invalid connection string.
- Resolution: Regenerated the connection string and stored it securely in an environment variable.


### Backup Size Management:
- Challenge: Large database dumps consumed significant disk space on the VM.
- Resolution: Implemented gzip compression and configured a cleanup script to remove backups older than 30 days.



## Outcomes
- Automation Achieved: The MySQL database is provisioned and configured automatically using Ansible, reducing setup time from hours to minutes.
- Reliable Backups: Daily backups are generated and stored in Azure Blob Storage, ensuring data recovery capabilities.
- Scalability: Azure Blob Storage provides virtually unlimited storage for backups, accommodating future growth.
- Security: Encrypted connection strings and Ansible Vault ensure sensitive data protection.
- Consistency: Ansible ensures identical configurations across multiple environments.

## Future Enhancements
- Backup Retention Policy: Implement a lifecycle policy in Azure Blob Storage to automatically manage backup retention.
- Monitoring: Integrate Azure Monitor or a third-party tool to alert on backup failures or anomalies.
- Multi-Region Backups: Store backups in multiple Azure regions for enhanced disaster recovery.
- Database Optimization: Add Ansible tasks to tune MySQL performance (e.g., adjust innodb_buffer_pool_size).

## Conclusion
This project successfully automated the provisioning of a MySQL database on an Azure VM, implemented a robust backup strategy, and integrated with Azure Blob Storage for scalable, secure storage. By addressing provisioning, backup, and recovery challenges, the solution ensures data integrity, operational efficiency, and scalability. The use of Ansible, MySQL, Azure, and cron provides a flexible and maintainable framework, making it a valuable for asset for organizations seeking to streamline their database management in the cloud.

