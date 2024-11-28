#!/bin/bash
# Gera arquivo .csv a partir de um arquivo .ics
# para importação no Google Calendar. Edite o script
# awk abaixo para customisar a saída como desejado.
# As colunas do arquivo .csv devem respeitar os nomes
# e formatos no link abaixo:
# https://support.google.com/calendar/answer/37118?sjid=976303939037949466-SA#format_csv&zippy=%2Ccreate-or-edit-a-csv-file

################################
# AWK scripts                  #
################################
read -d '' scriptVariable << 'EOF'
BEGIN {
    FS = ":"
    OFS = ","
    print "Start Date","Subject","All Day Event"
}

/^BEGIN:VCALENDAR/ {
    in_event = 0
}

/^BEGIN:VEVENT/ {
    in_event = 1
}

/^END:VEVENT/ {
    in_event = 0
    printf("%s,%s,True\\n", date, subj)
}

in_event {
    if ($1 == "DTSTART") {
        yyyy = substr($2,1,4)
	mm   = substr($2,6,2)
	dd   = substr($2,9,2)
	date = sprintf("%s/%s/%s", mm, dd, yyyy)
    }

    if ($1 == "SUMMARY") {
        subj = $2
    }
}
EOF
################################
# End of AWK Scripts           #
################################

if [ "$#" -ne 1 ]; then
    echo "Como usar: $(basename $0) {arquivo ics}"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Arquivo $1 não existe! Abortando..."
    exit 1
fi

# Caso queira remover o seu nome das descrições
# dos eventos, descomente a última linha, substituindo
# DAVI pelo seu nome de guerra, em caixa alta
awk "$scriptVariable" $1 \
    #| sed -E 's/DAVI //' | sed -E 's/\s+,/,/'
