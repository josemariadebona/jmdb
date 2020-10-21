#!/bin/bash

# https://datasets.imdbws.com/name.basics.tsv.gz
# https://datasets.imdbws.com/title.akas.tsv.gz
# https://datasets.imdbws.com/title.basics.tsv.gz
# https://datasets.imdbws.com/title.principals.tsv.gz

comillas () {
sqlite3 imdb.db "update $1 set $2=REPLACE($2,'\\\"','\"') where $2 like '%\"%';"
}


ddi () {
if [ ! -f $1.$2.q ]
then
	echo "Descargando fichero"
	wget https://datasets.imdbws.com/$1.$2.tsv.gz --no-check-certificate
	echo "Descomprimiendo fichero"
	gunzip $1.$2.tsv.gz
	echo "Quitando duplicados"
	sort $1.$2.tsv -u > $1.$2.tsv.s
	rm $1.$2.tsv
	echo "Convirtiendo comillas"
	sed 's/\"/\\\"/g' $1.$2.tsv.s > $1.$2.q
	rm $1.$2.tsv.s
fi

IFS=$'\t' read -r -a campos <<< `head -n 1 $1.$2.q`
echo "Insertando datos $1$2"
sqlite3 imdb.db <<- EOF
	DROP TABLE IF EXISTS $1$2;
	.mode tabs
	.import $1.$2.q $1$2
	.quit
EOF

# Si queremos conservar los ficheros descargados y convertidos, comentar la línea siguiente
#rm $1.$2.q

for campo in "${campos[@]}"
do
	echo "Reconvirtiendo comillas $1$2 $campo"
	comillas $1$2 $campo
done
}


ddi name basics
ddi title akas
ddi title basics
ddi title principals

# Para comentar todo el bloque, descomentar la siguiente línea:
#: <<- '#BLOQUECOMENTARIO'
# Si exite jmdb.db con la tabla de ficheros, podemos crear una imdb reducida:
if [ -f jmdb.db ]
then
echo Creando imdb_redux...
sqlite3 imdb_redux.db <<- EOF
    attach database 'imdb.db' as imdb;
    attach database 'jmdb.db' as jmdb;
    create table main.titlebasics as select * from imdb.titlebasics where tconst in (select distinct(tconst) from jmdb.ficheros);
    create table main.titleakas as select * from imdb.titleakas where titleid in (select tconst from main.titlebasics);
    create table main.titleprincipals as select * from imdb.titleprincipals where tconst in (select tconst from main.titlebasics);
    create table main.namebasics as select * from imdb.namebasics where nconst in (select distinct nconst from main.titleprincipals);
EOF
fi
#BLOQUECOMENTARIO
