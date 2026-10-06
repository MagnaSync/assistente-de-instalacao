#!/bin/bash

# ==================================================
# EXECUÇÃO - SCRIPT DE CAPTURA
# Projeto: Script-de-captura
# ==================================================

PASTA="$HOME/Script-de-captura"
ARQUIVO="script-de-captura-grupo.py"

echo "=========================================="
echo " INICIANDO SCRIPT DE CAPTURA"
echo "=========================================="

# --------------------------------------------------
# Verifica se a pasta existe
# --------------------------------------------------
if [ ! -d "$PASTA" ]; then
    echo "ERRO: A pasta $PASTA não existe."
    echo "Execute primeiro o script de configuração."
    exit 1
fi

# --------------------------------------------------
# Entra na pasta do projeto
# --------------------------------------------------
cd "$PASTA"

echo "Pasta do projeto:"
pwd

# --------------------------------------------------
# Verifica se o arquivo existe
# --------------------------------------------------
if [ ! -f "$ARQUIVO" ]; then
    echo "ERRO: O arquivo $ARQUIVO não foi encontrado."
    exit 1
fi

echo "Arquivo encontrado: $ARQUIVO"

# --------------------------------------------------
# Verifica versão do Python
# --------------------------------------------------
echo ""
echo "Python utilizado:"
python3 --version

# --------------------------------------------------
# Executa o projeto
# --------------------------------------------------
echo ""
echo "Iniciando aplicação..."
echo "=========================================="

python3 "$ARQUIVO"
