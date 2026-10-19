#!/bin/bash

REMETENTE="alerta@feliciano.dev.br"
DESTINO="dfeliciano37@gmail.com"
ASSUNTO="[hostname=$(hostname)] Relatório SMART NVMe"
DISCO="/dev/nvme0n1"

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
  <body style="font-family: monospace, Courier, monospace; background-color: #e8f5e9; padding: 10px;">
    <h2 style="color: #2e7d32;">$ASSUNTO - $DISCO</h2>
    <pre style="background-color: #ffffff; padding: 15px; border: 1px solid #a5d6a7; border-radius: 5px; font-size: 13px;">
$(nvme smart-log $DISCO)
    </pre>
  </body>
</html>
EOF
