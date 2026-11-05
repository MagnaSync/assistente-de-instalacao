#!/bin/bash

PROJETO="aplicao-web-api-WebDataViz"
SUBPASTA="web-data-viz"
DISCO="/dev/nvme1n1"

# Atualizar o sistema
echo "Gostaria de atualizar o SO? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo apt update -y
  sudo apt upgrade -y
fi

echo "Gostaria de instalar o Java? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo apt install openjdk-21-jdk -y
fi

java -version
python3 --version

# Instalar o Docker
echo "Gostaria de instalar o Docker? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo apt install docker.io git -y
  sudo systemctl start docker
  sudo systemctl enable docker
  docker --version
fi

# Disco EBS (rode esta parte só uma vez)
echo "Gostaria de preparar o disco EBS? [s/n]"
read get
if [ "$get" = "s" ]; then
  lsblk -e7
  sudo mkdir -p /dados
  sudo blkid $DISCO || sudo mkfs.ext4 $DISCO
  sudo mount $DISCO /dados
  sudo chown ubuntu:ubuntu /dados
  echo "UUID=$(sudo blkid -s UUID -o value $DISCO) /dados ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
fi

# Container do banco MySQL
echo "Gostaria de criar o container do banco MySQL? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo mkdir -p /dados/mysql

  read -s -p "Senha do root do MySQL: " SENHA_ROOT
  echo
  read -s -p "Senha do usuario aluno2: " SENHA_ALUNO
  echo

  sudo docker pull mysql:8
  sudo docker rm -f magnasync
  sudo docker run -d --name magnasync --restart unless-stopped \
    -p 3306:3306 \
    -v /dados/mysql:/var/lib/mysql \
    -e MYSQL_DATABASE=magnasync \
    -e MYSQL_ROOT_PASSWORD="$SENHA_ROOT" \
    -e MYSQL_USER=aluno2 \
    -e MYSQL_PASSWORD="$SENHA_ALUNO" \
    mysql:8

  echo "Aguardando o MySQL iniciar..."
  sleep 10

  sudo docker ps -a
  sudo docker logs --tail 5 magnasync

  # Importar o script SQL (arquivo banco.sql na mesma pasta do script)
 echo "Gostaria de importar o banco.sql? [s/n]"
 read get
 if [ "$get" = "s" ]; then
  read -s -p "Senha do root do MySQL: " SENHA_ROOT
  echo
  git clone https://github.com/MagnaSync/database-mysql-schema
  sudo docker exec -i -e MYSQL_PWD="$SENHA_ROOT" magnasync mysql -uroot < database-mysql-schema/magnasync_script.sql
  sudo docker exec -e MYSQL_PWD="$SENHA_ROOT" magnasync mysql -uroot -e "USE magnasync; SHOW TABLES;"
 fi
fi

# Clonar o projeto
echo "Gostaria de clonar o projeto? [s/n]"
read get
if [ "$get" = "s" ]; then
  rm -rf "$PROJETO"
  git clone https://github.com/MagnaSync/aplicao-web-api-WebDataViz.git
fi

cd "$PROJETO/$SUBPASTA" || exit 1

# Criar o Dockerfile
cat << EOF > Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3333
CMD ["npm", "start"]
EOF

# Criar a imagem e executar a API
sudo docker build -t aplicao-web-api-webdataviz-imagem:1.0 .

read -s -p "Senha do usuario aluno2: " SENHA_ALUNO
echo

sudo docker rm -f site
sudo docker run -d --name site --restart unless-stopped \
  -p 3333:3333 \
  -e DB_HOST=$(hostname -I | cut -d' ' -f1) \
  -e DB_PORT=3306 \
  -e DB_DATABASE=magnasync \
  -e DB_USER=aluno2 \
  -e DB_PASSWORD="$SENHA_ALUNO" \
  aplicao-web-api-webdataviz-imagem:1.0

echo "API iniciada no Docker."