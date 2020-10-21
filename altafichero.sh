existe=`sqlite3 jmdb.db "select tconst from ficheros where nombre='$1';"`
tam=`du -b "$1" | cut -f 1`
tconst=`echo ${1##*/} | cut -d ' ' -f 1 | cut -d '.' -f 1`
timestamp=`date '+%Y%m%d%H%M%S' -r "$1"`
datos1=`mediainfo --Inform="Video;%Height% %Width%" "$1"`
read alto ancho <<< `echo $datos1`
if [ "$alto" = "" ]
then
  alto=0
fi
if [ "$ancho" = "" ]
then
  ancho=0
fi
datos2=`mediainfo "--Inform=General;%Duration% %AudioCount%;" "$1"`
read duracion AudiosNum <<< `echo $datos2`
#AudiosNum=`mediainfo "--Inform=General;%AudioCount%;" "$1"`
if [ "$duracion" = "" ]
then
  duracion=0
fi
if [ "$AudiosNum" = "" ]
then
  AudiosNum=0
fi
AudiosDesc=`mediainfo "--Inform=Audio;%Language/String%," "$1"`
SubTNum=`mediainfo "--Inform=General;%TextCount%;" "$1"`
if [ "$SubTNum" = "" ]
then
  SubTNum=0;
fi
SubTDesc=`mediainfo "--Inform=Text;%Language/String%," "$1"`
if [ "$existe" = "" ]
then
  sqlite3 jmdb.db "insert into ficheros(tconst,nombre,duracion,ancho,alto,tam,timestamp,numAudios,audios,numSubt,subtitulos) values('$tconst','$1',$duracion,$ancho,$alto,$tam,'$timestamp',$AudiosNum,'$AudiosDesc',$SubTNum,'$SubTDesc');"
  echo Creado nuevo registro $tconst
  s=$((duracion/1000))
  m=$((s/60))
  h=$((m/60))
  m=$((m-s*60))
  s=$((s-m*60-h*3600))
  echo "$tconst - $1"
  echo "Tamaño: $tam Fecha y hora: $timestamp"
  echo "Resolución: $ancho x $alto Duración: $duracion ($h $m $s)"
  echo "Audios: $AudiosNum ($AudiosDesc) Subtítulos: $SubTNum ($SubTDesc)"
else
  echo $tconst ya existe.
fi

