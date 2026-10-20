#!/bin/bash

REMETENTE="alerta@feliciano.dev.br"
DESTINO="dfeliciano37@gmail.com"
ASSUNTO="[hostname=$(hostname)] Alerta Crítico no NVMe"
DISCO="/dev/nvme0n1"
ESTADO_ARQUIVO="/var/tmp/nvme_estado_alerta.txt"
DADOS=$(nvme smart-log $DISCO)

CRIT_WARN=$(echo $DADOS | grep "^critical_warning" | awk '{print $3}')
MEDIA_ERR=$(echo $DADOS | grep "^media_errors" | awk '{print $3}')
SPARE=$(echo $DADOS | grep "^available_spare\s" | awk '{print $3}' | tr -d '%')
SPARE_THRESH=$(echo $DADOS | grep "^available_spare_threshold" | awk '{print $3}' | tr -d '%')

CRIT_WARN=${CRIT_WARN:-0}
MEDIA_ERR=${MEDIA_ERR:-0}
SPARE=${SPARE:-100}
SPARE_THRESH=${SPARE_THRESH:-10}

if [ "$CRIT_WARN" != "0" ] || [ "$MEDIA_ERR" != "0" ] || [ "$SPARE" -le "$SPARE_THRESH" ]; then
    ESTADO_ATUAL="${CRIT_WARN}_${MEDIA_ERR}_${SPARE}"
    ESTADO_ANTERIOR=""
    
    if [ -f "$ESTADO_ARQUIVO" ]; then
        ESTADO_ANTERIOR=$(cat "$ESTADO_ARQUIVO")
    fi

    if [ "$ESTADO_ATUAL" != "$ESTADO_ANTERIOR" ]; then
        cat <<EOF | msmtp -t
Date: $(date -R)
From: $REMETENTE
To: $DESTINO
Subject: $ASSUNTO
MIME-Version: 1.0
Content-Type: text/html; charset=utf-8
Content-Disposition: inline
Content-Transfer-Encoding: 8bit

<html>
  <body style="font-family: monospace, Courier, monospace; background-color: #ffebee; padding: 10px;">
    <h2 style="color: #c62828;">$ASSUNTO - $DISCO</h2>
    <p style="color: #b71c1c;"><strong>Atenção:</strong> O disco reportou parâmetros críticos de degradação física.</p>
    <ul style="color: #b71c1c;">
      <li><strong>Critical Warning:</strong> $CRIT_WARN (Ideal: 0)</li>
      <li><strong>Media Errors:</strong> $MEDIA_ERR (Ideal: 0)</li>
      <li><strong>Available Spare:</strong> ${SPARE}% (Limite de segurança: ${SPARE_THRESH}%)</li> 
    </ul>
    <pre style="background-color: #ffffff; padding: 15px; border: 1px solid #ef9a9a; border-radius: 5px; font-size: 13px;">
$DADOS
    </pre>
  </body>
</html>
EOF
        
        echo "$ESTADO_ATUAL" > "$ESTADO_ARQUIVO"
    fi
else
    if [ -f "$ESTADO_ARQUIVO" ]; then
        rm -f "$ESTADO_ARQUIVO"
    fi
fi
