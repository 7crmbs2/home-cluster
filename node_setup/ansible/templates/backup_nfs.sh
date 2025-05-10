#!/usr/bin/env bash

##
## Set environment variables
##

## if you don't use the standard SSH key,
## you have to specify the path to the key like this
# export BORG_RSH='ssh -i /home/userXY/.ssh/id_ed25519'

## You can save your borg passphrase in an environment
## variable, so you don't need to type it in when using borg
export BORG_PASSPHRASE='{{ borgPassphrase }}'

##
## Set some variables
##

export LOG='/var/log/borg/backup.log'
export BACKUP_USER='{{ borgUsername }}'
export REPOSITORY_DIR='backup'

## Tip: If using with a Backup Space you have to use
## 'your-storagebox.de' instead of 'your-backup.de'

export REPOSITORY="ssh://${BACKUP_USER}@${BACKUP_USER}.your-storagebox.de:23/./${REPOSITORY_DIR}"

##
## Output to a logfile
##

exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Backup started: $(date) ######"

##
## At this place you could perform different tasks
## that will take place before the backup, e.g.
##
## - Create a list of installed software
## - Create a database dump
##

##
## Transfer the files into the repository.
## In this example the folders root, etc,
## var/www and home will be saved.
## In addition you find a list of excludes that should not
## be in a backup and are excluded by default.
##

echo "Backing up cube PVCs ..."
borg create --stats                   \
    $REPOSITORY::'cubes-{now:%Y-%m-%d_%H:%M}'                                                                       \
    /mnt/raidstorage                                                                                           \
    --exclude /mnt/raidstorage/jellyfin-jellyfin-media-pvc-1bf5c827-dad7-4b8c-bf3b-6c5b4338ccfe/

echo "###### Backup ended: $(date) ######"
