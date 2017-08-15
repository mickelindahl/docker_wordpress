# Docker wordpress

# Backup

Create directory backups if not already done
```
mkdir backups
```

Create backup dr with todays date inside `backups/`
```
mkdir backups/backup_{date}
```

Backup mysql from container run

```
docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > /backups/backups_{date}/backup.sql
```
   
Copy hmtl

```
cp -R html backups/backups_{date}
```

Done!


