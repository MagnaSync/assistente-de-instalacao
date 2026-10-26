#!/bin/bash

PROJETO="aplicao-web-api-WebDataViz"
SUBPASTA="web-data-viz"

# Atualizar o sistema
echo "Gostaria de atualizar o SO? [s/n]"
read get

if [ "$get" = "s" ]; then
sudo apt update -y
sudo apt upgrade -y
echo "Sistema atualizado com sucesso."
fi

echo "Gostaria de instalar a versão java? [s/n]"
read get

if [ "$get" = "s" ]; then
sudo apt update -y
sudo apt install openjdk-25-jdk -y
echo "Java instalado com sucesso."
fi

# Verificar versões de aplicações
java -version
python3 --version

echo "As versões do sistema foram verificadas."

# Instalar o Docker
echo "Gostaria de instalar o Docker? [s/n]"
read get

if [ "$get" = "s" ]; then
sudo apt update
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version
echo "Docker instalado com sucesso."
fi


# Clonar o projeto
echo "Gostaria de clonar o projeto? [s/n]"
read get

if [ "$get" = "s" ]; then

if [ -d "$PROJETO" ]; then
echo "Repositório já existe. Removendo versão antiga..."
rm -rf "$PROJETO"
fi

git clone https://github.com/MagnaSync/aplicao-web-api-WebDataViz.git
echo "Projeto clonado com sucesso."
fi

#Verifica se ja foi clonado
if [! -d "$PROJETO"]; then
echo "Pasta $PROJETO não encontrada. Clone seu projeto primeiro."
exit 1

fi



cd "$PROJETO/$SUBPASTA" || exit 1


if [! -f package.json]; then
  echo "package.json não encontrado em $(pwd)."
  exit 1

fi

# Criar o Dockerfile
     cat << EOF > Dockerfile
FROM node:20-alpine

WORKDIR /app

COPY . .

RUN npm install

EXPOSE 3333

CMD ["npm", "start"]
EOF

    echo "Dockerfile criado com sucesso."

# Criar a imagem Docker
sudo docker build -t aplicao-web-api-webdataviz-imagem:1.0 .

# Executar a API no contêiner
sudo docker rm  -f site 2>/dev/null
sudo docker run -d \
--name site \
-p 3333:3333 \
aplicao-web-api-webdataviz-imagem:1.0

echo "API iniciada no Docker."