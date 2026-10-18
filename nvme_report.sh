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
<body style="font-family: monospace, courier, monospace;">
<pre>
$(nvme smart-log $DISCO)
</pre>
</body>
</html>
EOF
