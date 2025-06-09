!/bin/bash

# MySQL user
MYSQL_USER="dbuser"
# MySQL password
MYSQL_PASSWORD="mypass"  # <-- Replace with dbuser's actual password
# Backup directory
BACKUP_DIR="/home/azureuser/backups/mysql"
# Timestamp for filename
DATE=$(date +"%Y%m%d_%H%M%S")
# Backup filename
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Run mysqldump
mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD \
  --all-databases \
  --no-tablespaces > $BACKUP_FILE

# Optional: Compress the backup
gzip $BACKUP_FILE

echo "Backup completed: $BACKUP_FILE.gz
