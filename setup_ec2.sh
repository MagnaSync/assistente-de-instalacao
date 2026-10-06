#!/bin/bash

# ==================================================
# CONFIGURAÇÃO AUTOMÁTICA - EC2 UBUNTU SERVER
# Projeto: Script-de-captura
# ==================================================

set -e

REPO="https://github.com/MagnaSync/monitaramento-python-hardware.git"
PASTA="monitoramento-python-hardware"

MYSQL_USER="ec2"
MYSQL_PASS="ec2123"
DATABASE="grupo10"

echo "=========================================="
echo " INICIANDO CONFIGURAÇÃO DA INSTÂNCIA EC2"
echo "=========================================="

# --------------------------------------------------
# 1. Atualização do sistema
# --------------------------------------------------
echo ""
echo "[1/7] Atualizando o sistema..."

sudo apt update -y
sudo apt upgrade -y

echo "Sistema atualizado com sucesso."

# --------------------------------------------------
# 2. Clonando repositório
# --------------------------------------------------
echo ""
echo "[2/7] Clonando repositório..."

if [ -d "$PASTA" ]; then
    echo "Repositório já existe. Removendo versão antiga..."
    rm -rf "$PASTA"
fi

git clone "$REPO"

echo "Repositório clonado com sucesso."

# --------------------------------------------------
# 3. Instalação e configuração do MySQL
# --------------------------------------------------
echo ""
echo "[3/7] Instalando MySQL Server..."

sudo apt install mysql-server -y

sudo systemctl enable mysql
sudo systemctl start mysql

echo "Criando banco e usuário..."

sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $DATABASE;

CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASS';

GRANT ALL PRIVILEGES ON $DATABASE.* TO '$MYSQL_USER'@'%';

FLUSH PRIVILEGES;
EOF

echo "Importando scriptModel.sql..."

SCRIPT_SQL="$HOME/$PASTA/scriptModel.sql"

if [ -f "$SCRIPT_SQL" ]; then
    sudo mysql "$DATABASE" < "$SCRIPT_SQL"
    echo "Tabelas importadas com sucesso."
else
    echo "ERRO: scriptModel.sql não encontrado em:"
    echo "$SCRIPT_SQL"
    exit 1
fi

echo "Banco '$DATABASE' criado."
echo "Usuário '$MYSQL_USER' configurado."

echo "Habilitando acesso remoto do MySQL..."

sudo sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' \
/etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql

echo "MySQL configurado com sucesso."

# --------------------------------------------------
# 5. Verificação da porta 3306
# --------------------------------------------------
echo ""
echo "[5/7] Verificando porta 3306..."

if ss -tuln | grep -q ":3306"; then
    echo "OK - Porta 3306 está aberta e o MySQL está escutando."
else
    echo "ATENÇÃO - Porta 3306 não está em execução."
    echo "Verifique o serviço: sudo systemctl status mysql"
fi

# --------------------------------------------------
# 6. Instalação das bibliotecas do projeto
# --------------------------------------------------
echo ""
echo "[6/7] Instalando bibliotecas do requirements.txt..."

cd "$HOME/$PASTA"

echo "Atualizando pip..."

python3 -m pip install --upgrade pip --break-system-packages

if [ -f requirements.txt ]; then
    echo "requirements.txt encontrado."
    python3 -m pip install -r requirements.txt --break-system-packages
    echo "Bibliotecas instaladas com sucesso."
else
    echo "Arquivo requirements.txt não encontrado!"
fi

# --------------------------------------------------
# 7. Finalização
# --------------------------------------------------
echo ""
echo "[7/7] Verificando serviços..."

sudo systemctl is-active mysql

echo ""
echo "=========================================="
echo " CONFIGURAÇÃO CONCLUÍDA COM SUCESSO "
echo "=========================================="
echo ""
echo "Resumo:"
echo "Repositório : $PASTA"
echo "Banco       : $DATABASE"
echo "Usuário     : $MYSQL_USER"
echo "Senha       : $MYSQL_PASS"
echo "Python      : $(python3 --version)"
echo "MySQL       : $(mysql --version)"
echo ""
echo "A aplicação está pronta para execução."