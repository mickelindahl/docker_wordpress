#:/bin/bash

# Example:
# Woth port mapping
# generate_docker_compose_file.sh test secret
# or with vituaal host
# generate_docker_compose_file.sh test secret a.domain.com


NAME=$1
PASSWORD=$2

cp sample.docker-compose.yml docker-compose.yml

sed -i "s#{name}#"${NAME}"#g" docker-compose.yml 
sed -i "s#{password}#"${PASSWORD}"#g" docker-compose.yml 

# Set virtual host entry
if [ -z "$3" ]; then
    sed -i "s/{ports-web}/ports:/g" docker-compose.yml 
    sed -i "s/{port-mapping-web}/- 8080:80/g" docker-compose.yml 
    sed -i "s/{virtual-host}/#VIRTUAL_HOST:""/g" docker-compose.yml 

#fi
else
# Set port entries
#if [ "$3" -eq "with-virtual-host" ]
#then
    sed -i "s/{virtual-host}/VIRTUAL_HOST:" ${3}"/g" docker-compose.yml 
    sed -i "s/{ports-web}/#ports:/g" docker-compose.yml 
    sed -i "s/{port-mapping-web}/#- 8080:80/g" docker-compose.ym
fi

