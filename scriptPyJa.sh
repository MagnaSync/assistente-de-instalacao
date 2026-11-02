#!/bin/bash

REPO_JAVA="https://github.com/MagnaSync/monitoramento-java-rede.git"
REPO_PYTHON="https://github.com/MagnaSync/monitoramento-python-hardware.git"
PASTA_JAVA="monitoramento-java-rede"
PASTA_PYTHON="monitoramento-python-hardware"
SUBPASTA_JAVA="ScriptJavaMagnaSync"

BANCO="magnasync"
USUARIO_BD="aluno2"
RAIZ=$(pwd)

# Atualizar o sistema
echo "Gostaria de atualizar o SO? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo apt update -y
  sudo apt upgrade -y
fi

# Instalar o Docker
echo "Gostaria de instalar o Docker? [s/n]"
read get
if [ "$get" = "s" ]; then
  sudo apt update -y
  sudo apt install docker.io git -y
  sudo systemctl start docker
  sudo systemctl enable docker
  docker --version
fi

if ! command -v docker > /dev/null; then
  echo "Docker nao esta instalado. Rode de novo e responda s em Instalar o Docker."
  exit 1
fi

# Dados da VM do banco
read -p "IP privado da VM do banco: " DB_HOST
read -s -p "Senha do usuario aluno2: " SENHA_ALUNO
echo

# Testa se a porta 3306 da VM do banco esta acessivel
if timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/3306" 2> /dev/null; then
  echo "Conexao com o banco OK."
else
  echo "Nao foi possivel conectar em $DB_HOST:3306."
  echo "Confira o IP, o Security Group e se o container magnasync esta rodando."
  exit 1
fi

# Clonar os projetos
echo "Gostaria de clonar os projetos? [s/n]"
read get
if [ "$get" = "s" ]; then
  rm -rf "$PASTA_JAVA" "$PASTA_PYTHON"
  git clone "$REPO_JAVA"
  git clone "$REPO_PYTHON"
fi

if [ ! -d "$PASTA_JAVA" ] || [ ! -d "$PASTA_PYTHON" ]; then
  echo "Projetos nao encontrados. Clone os projetos primeiro."
  exit 1
fi

# Confere se os projetos ja foram ajustados para ler o banco por variavel de ambiente
if ! grep -q "jdbc:mysql" "$PASTA_JAVA/$SUBPASTA_JAVA/src/main/java/org/MagnaSync/DBConnectionProvider.java"; then
  echo "O projeto Java ainda usa o banco H2 em memoria (nao grava no MySQL)."
  echo "Ajuste o DBConnectionProvider.java e o Main.java, de commit e rode de novo."
  exit 1
fi

if ! grep -q "esperarEquipamento" "$PASTA_JAVA/$SUBPASTA_JAVA/src/main/java/org/MagnaSync/Main.java"; then
  echo "O Main.java do Java ainda e a versao antiga (cria a tabela leitura e nao usa o equipamento)."
  echo "Troque pelo Main.java novo, de commit e rode de novo."
  exit 1
fi

if ! grep -q "environ" "$PASTA_PYTHON/script-captura-magnaSync.py"; then
  echo "O script Python ainda tem host/usuario/senha fixos no codigo."
  echo "Ajuste a conexao para ler os dados de os.environ, de commit e rode de novo."
  exit 1
fi

# ---------- Java ----------
cd "$RAIZ/$PASTA_JAVA/$SUBPASTA_JAVA" || exit 1

cat << EOF > Dockerfile
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /build
COPY . .
RUN mvn -q -DskipTests package

FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /build/target/ScriptJavaMagnaSync-1.0-SNAPSHOT.jar app.jar
CMD ["java", "--enable-native-access=ALL-UNNAMED", "-jar", "app.jar"]
EOF

sudo docker build -t magnasync-java:1.0 .

sudo docker rm -f monitoramento-java
sudo docker run -d --name monitoramento-java --restart unless-stopped \
  --network host \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT=3306 \
  -e DB_DATABASE="$BANCO" \
  -e DB_USER="$USUARIO_BD" \
  -e DB_PASSWORD="$SENHA_ALUNO" \
  magnasync-java:1.0

# ---------- Python ----------
cd "$RAIZ/$PASTA_PYTHON" || exit 1

cat << EOF > Dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir psutil mysql-connector-python
COPY script-captura-magnaSync.py .
CMD ["python", "-u", "script-captura-magnaSync.py"]
EOF

sudo docker build -t magnasync-python:1.0 .

# -dit: o script Python tem menu interativo, entao o container precisa de terminal
sudo docker rm -f monitoramento-python
sudo docker run -dit --name monitoramento-python --restart unless-stopped \
  --network host \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT=3306 \
  -e DB_DATABASE="$BANCO" \
  -e DB_USER="$USUARIO_BD" \
  -e DB_PASSWORD="$SENHA_ALUNO" \
  magnasync-python:1.0

cd "$RAIZ"
sudo docker ps
echo "Ultimas linhas do log do Java:"
sleep 5
sudo docker logs --tail 10 monitoramento-java

echo "Para usar o menu do Python:  sudo docker attach monitoramento-python"
echo "Para sair do menu sem parar o container: Ctrl+P e depois Ctrl+Q"