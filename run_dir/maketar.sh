CURRENTDATE=`date +"%Y-%m-%d"` 
tar -cvf tars/$1_${CURRENTDATE}.tar.gz $1/*/*/*/*/*/*.csv $1/*/*/*/*/*/*.txt

