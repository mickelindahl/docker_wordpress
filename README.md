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

Run migration and follow instructions
```
./migrate.sh

```
Gå till 
```
{site-url}/wp-admin

```

WARNING!!! Make sure you are att new_url and is not modifying the production site

Logga in och gå till **verkty**->**Update url** and run url update on site. Replace old url with new url

Gå till **Inställningar**->**permalänkar** and set **Vanliga inställningar** to **Enkel**
Then switch it back to what it was before. This is a fix so that /{url} will be find ([reference](https://www.youtube.com/watch?v=HedHYNpqoOg))

Om du har woocomerce gå till **Woocomerce**->**Inställningar**->**kassa** och clicka bort att https krävs


## Install theme from git repository
Go to html/wp-content/themes
Clone you code for theme
Move old theme
Change name of clone theme ot theme used
Change owner to www-data
Change right to 775
Install node dependencies


