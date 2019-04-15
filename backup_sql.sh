#!/bin/bash
#Script make optimize all database and back SQL databases
#for works you need set chmod 700 for script.sh


#############DATA
PASSWORD=pass #pass mysql root
USER=login #user mysql
DATE=`date +%d-%m-%Y` #date
BACKUPDIR=/home/user123/mybackup/sql
TEMPDIR=/var/backuper/sql_$DATE
COMPRESSED_FILE_FULL_PATH=$BACKUPDIR/linode_backup_sql_$DATE.tar.gz
##Yandex Disk Data
YANDEX_FILENAME=$COMPRESSED_FILE_FULL_PATH
YANDEX_LOGIN=login
YANDEX_PASS=pass
###########################################

#optimize all databases
mysqlcheck -u$USER -p$PASSWORD --optimize --all-databases
echo -e "\nOptimize databases cancel\n"

#make temp dir for sql backups
if ! [ -d $TEMPDIR ]; then
	mkdir -p $TEMPDIR  
fi
	
#create databases list
mysql -u$USER -p$PASSWORD -e "show databases;" > /tmp/tempdatabases.list

#create stop list databases and words
echo -e "Database\ninformation_schema\nmysql\nperformance_schema\nroundcube\ntest" > /tmp/stoplist.txt

#delete stoplist lines in databases list
grep --ignore-case -vf  /tmp/stoplist.txt /tmp/tempdatabases.list > /tmp/alldatabases.list

#backup database
echo -e "\nBackup start, wait...\n"

file="/tmp/alldatabases.list"
IFS=$'\n' ######look https://habr.com/ru/company/ruvds/blog/325928/
for namefile in $(cat $file)
do
echo -e "\nbackup database $namefile\n"
mysqldump -u$USER -p$PASSWORD $namefile > $TEMPDIR/$namefile\_$DATE.sql
done

echo -e "\nStart compress backup...\n"

#check for the existence of a directory
if ! [ -d $BACKUPDIR ]; then   ##if the directory does not exist
	echo -e "\ncreate directory for backup\n"
	mkdir -p $BACKUPDIR
fi

tar -P -czvf  $COMPRESSED_FILE_FULL_PATH  $TEMPDIR

echo -e "\nCompress done\nStart Upload to Yandex Disk\n"
curl -T $YANDEX_FILENAME https://webdav.yandex.ru/mysqlbackups/linode/ --user $YANDEX_LOGIN:$YANDEX_PASS --progress-bar -o /dev/null

#cancel, delete temp files
rm -f /tmp/tempdatabases.list /tmp/stoplist.txt /tmp/alldatabases.list $TEMPDIR/*
rmdir $TEMPDIR
echo -e "\nAll done!\n"