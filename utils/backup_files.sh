#!/bin/bash
# Script para realizar backup/restore de la herramienta

# Inicialización de variables
FECHA=`date +%Y%m%d`

Backup() {

    mkdir -p /tmp/omnileads-backup/$FECHA-omnileads-backup

    #Asterisk Files
    echo "Making backup of asterisk files"
    mkdir -p /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/etc
    mkdir -p /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/agi-bin
    mkdir -p /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/sounds
    cp -a --preserve=links /opt/omnileads/asterisk/etc/asterisk/oml_extensions* /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/etc
    cp /opt/omnileads/asterisk/var/lib/asterisk/agi-bin/*.py /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/agi-bin
    cp -a /opt/omnileads/asterisk/var/lib/asterisk/sounds/oml/ /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/sounds
    tar czvf /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk.tgz /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/* > /dev/null 2>&1
    rm -rf /tmp/omnileads-backup/$FECHA-omnileads-backup/asterisk/
    sleep 3

    #Omniapp files
    echo "Making backup of csv's and system audios"
    mkdir -p /tmp/omnileads-backup/$FECHA-omnileads-backup/omniapp
    cp -a /opt/omnileads/media_root/ /tmp/omnileads-backup/$FECHA-omnileads-backup/omniapp/
    tar czvf /tmp/omnileads-backup/$FECHA-omnileads-backup/omniapp.tgz /tmp/omnileads-backup/$FECHA-omnileads-backup/omniapp/* > /dev/null 2>&1
    rm -rf /tmp/omnileads-backup/$FECHA-omnileads-backup/omniapp/
    sleep 3

    #Kamailio Files
    echo "Making backup of kamailio configuration file"
    mkdir /tmp/omnileads-backup/$FECHA-omnileads-backup/kamailio
    cp -a --preserve=links /opt/omnileads/kamailio/etc/ /tmp/omnileads-backup/$FECHA-omnileads-backup/kamailio
    tar czvf /tmp/omnileads-backup/$FECHA-omnileads-backup/kamailio.tgz /tmp/omnileads-backup/$FECHA-omnileads-backup/kamailio/* > /dev/null 2>&1
    rm -rf /tmp/omnileads-backup/$FECHA-omnileads-backup/kamailio/
    sleep 3

    # Tar the last directory
    tar czvf $FECHA-omnileads-backup.tgz /tmp/omnileads-backup/$FECHA-omnileads-backup/ > /dev/null 2>&1
    cd /tmp/omnileads-backup && tar czvf $FECHA-omnileads-files-backup.tgz $FECHA-omnileads-backup
    mv /tmp/omnileads-backup/$FECHA-omnileads-files-backup.tgz /opt/omnileads/backup
    rm -rf /tmp/omnileads-backup/ /opt/omnileads/bin/*backup

    backup_location="`basename /opt/omnileads/backup/${FECHA}*`"
    echo -e "\n Backup made in this file: $backup_location "
    echo -e "Now you can restore doing: ./backup-restore.sh -r $backup_location"
}

Restore() {
    set -e
    ARRAY=(asterisk.tgz kamailio.tgz omniapp.tgz)
    tar_backup=$1
    tar_directory=`echo $1 | awk -F "." '{print $1}'`
    cd /opt/omnileads/backup
    tar xzvf $tar_backup > /dev/null 2>&1
    cd $tar_directory
    for counter in {0..3}; do
        tar xzvf ${ARRAY[counter]} > /dev/null 2>&1
    done
    cd tmp/omnileads-backup/$tar_directory/

    #Restore of asterisk files
    echo "Restoring asterisk files and audios"
    cd asterisk
    cp -a agi-bin/* /opt/omnileads/asterisk/var/lib/asterisk/agi-bin/
    cp -a --preserve=links etc/oml_extensions* /opt/omnileads/asterisk/etc/asterisk/
    cp -a sounds/* /opt/omnileads/asterisk/var/lib/asterisk/sounds/

    #Restore of omniapp files
    echo "Restoring omniapp csv's and system audios"
    cd ../omniapp
    cp -a media_root/* /opt/omnileads//media_root

    #Restore of kamailio files
    echo "Restoring kamailio files"
    cd ../kamailio/etc
  #  cp -a certs /opt/omnileads/kamailio/etc/certs > /dev/null 2>&1
    cp -a --preserve=links kamailio /opt/omnileads/kamailio/etc/kamailio > /dev/null 2>&1

    rm -rf /opt/omnileads/backup/$tar_directory
    rm -rf /opt/omnileads/bin/$tar_directory

}

while getopts "r:b" OPTION;do
	case "${OPTION}" in
		r) # Opcion para realizar restore, argumento: Nombre del tgz
            Restore $OPTARG
		;;
		b) #Opcion para realizar backup
		    Backup
		;;
	esac
done
if [ $# -eq 0  ]; then echo -n; fi
