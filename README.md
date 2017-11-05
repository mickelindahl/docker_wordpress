# Docker wordpress

# Installation

Run `generate_compose_file.sh` 

Either with port mapp 
```
generate_docker_compose_file.sh test secret
```
Or with vitual host
```
generate_docker_compose_file.sh test secret a.domain.com
```

Then build and start
```
docker up-d
```

Done!

# Backup

Create directory backups if not already done
```
mkdir backups
```

Create backup dr with todays date inside `backups/`
```
mkdir backups/backup_{date}
```

Copy hmtl

```
cp -R html backups/backups_{date}
```

Backup mysql from container run

```
cd backups/backup_{date}
docker exec {container id} /usr/bin/mysqldump -u {database user} --password={database password} {password} > backup.sql
```
   

Done!


