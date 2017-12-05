# Docker wordpress

## Installation

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

## Backup

### Manual


Run
```
sudo ./backup.sh {container-id} {db-name} {'db-user} {db-pass}          
```

Done!

### Cron

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

## Migrate

Ensure your user belongs to www-data group
```
sudo usermod -a -G www-data mikael
```
OBS! Need to restart computer for this to take effect

Extract html and database.sql. Se create backup.

Copy over html directory and backup.sql
```
scp -r {user}@{domain}:{backup-dir} 

```

Eter backup dir and extract hmtl
```
tar -zxvf html.tar.gz 
```

Change owner
```
chown -R www-data:www-data html
```

Edit wp-config.php
```
cd hmtl
nano wp-config.php
``` 
Set DB_USER, DB_PASSWORD and DB_HOST 
These are found in the docer-compose.yml file. 
DB_HOST is  the mysql databes  service name in docker-compose file)


Copy hmtl to wordpress soruces dir
```
cp {backup-root}/html {source-root}/html
```

Restore db
```
cd {backup-root}
cat backup.sql | docker exec -i {container-id} /usr/bin/mysql -u {db-user} --password={db-pass} {db-name}
```

edit function.php, add emediatly after "<?php" line
```
update_option( 'siteurl', 'http://127.0.0.1:8080/' );
update_option( 'home', 'http://127.0.0.1:8080/' );
```

Go to html/wp-content/themes
Clone you code for theme
Move old theme
Change name of clone theme ot theme used
Change owner to www-data
Change right to 775
Install node dependencies


