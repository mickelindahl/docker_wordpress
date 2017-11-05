# Docker wordpress

# Backup

## Manual

Run
```
sudo ./backup.sh {container-id} {db-name} {'db-user} {db-pass}          
```

Done!

## Cron

Setup a cronjob that backups day 1,7,14,21, and 28 of the month

Run 
```
sudo su
crontab -e
```
Pase
```
00 01 1,7,14,21,28 * * {source-root}/backup.sh {container-id} {db-name} {'db-user} {db-pass} `date +%d`
```
Save

Done!

