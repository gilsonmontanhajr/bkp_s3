#!/bin/bash

# variáveis do sistema
EU=`whoami`
MEUDIR=`pwd`
DIR_LOGS="/var/log/bkp-s3/"
DIR_HTML="/var/www/html/"
HJ_DT=`date +%d-%m-%y`
HJ_HR=`date +%H:%M:%S`
SYNC=`s3cmd sync --verbose --exclude 'temp/'`
S3POOL="s3://bkp_manusis.wolk.com.br/"

# Criando Diretórios de log e arquivos
# Função responsável por ver se diretório /var/log/bkp-s3 existe.
# Ele cria sempre 3 arquivos :
# 1 : mensagens.log   -> Responsável pelas mensagens do script
# 2 : DATA.log        -> Grava a saída do backup
# 3 : lista-DATA.log  -> Gera a lista de diretórios
function geradirs(){
  if [ -e $DIR_LOGS ]; then
    touch $DIR_LOGS"mensagens.log"
    touch $DIR_LOGS$HJ_DT.log
    touch $DIR_LOGS"lista-"$HJ_DT".log"
  else
    mkdir -p $DIR_LOGS
    touch $DIR_LOGS"mensagens.log"
    touch $DIR_LOGS$HJ_DT.log
    touch $DIR_LOGS"lista-"$HJ_DT".log"
  fi
}

# Gerando a lista de diretórios
function geralista(){
  ls -F $DIR_HTML | grep $'/' > $DIR_LOGS"lista-"$HJ_DT".log"

  # Varrendo os diretórios
  while read linha
  do
    ARQUIVOS="$DIR_HTML$linha/arquivos"
    if [ -e $ARQUIVOS ]; then
      # Caso o diretório exista
      echo "Fazendo backup do projeto ${linha} !";
      # Fazendo a sincronização de fato
      # Exemplo de sincronização com comando
      # s3cmd sync --verbose --exclude 'temp/*' /var/www/html/projeto/arquivos/ s3://bkp_manusis.wolk.com.br/projeto/ >> /var/log/bkp/log.log
      $SYNC $DIR_HTML$linha"arquivos/" $S3POOL$linha >> $DIR_LOGS$HJ_DT".log"
      # Escrevendo as mensagens para enviar por email.
      echo "Sincronização do projeto ${linha} está OK !" >> $DIR_LOGS"mensagens.log"
      echo "---" >> $DIR_LOGS"mensagens.log"
      sleep 2;
      # Enviando email
      cat $DIR_LOGS"mensagens.log" | mail -s bkp_manusis_${HJ_DT} infra@wolk.com.br
    else
      echo "Diretório ARQUIVOSdo projeto ${linha} NÃO existe !" >> $DIR_LOGS"mensagens.log"
    fi

  done < $DIR_LOGS"lista-"$HJ_DT".log"
}


geradirs
geralista
