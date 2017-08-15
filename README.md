# Docker wordpress

# Backup

To backup mysql from container run

```
docker exec CONTAINER /usr/bin/mysqldump -u root --password=root DATABASE > backup.sql 
```


