#!/bin/bash
# Script provided by Damiano Rubcic, Professional Services Consultant, Tufin
# Disclaimer: This script is a third-party development and is not supported by Tufin. Use it at your own risk
# Version: 1.0

export PATH="${PATH}:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"

timestamp() {
echo -n "[`date --rfc-3339=seconds`] "
}


check_perm() {

  whoami=`whoami`
  timestamp
  echo "current user is $whoami"

  timestamp
  perm=`ls -l $0 | awk '{print $1}'`

  if [[ $perm = "-rwx------" ]]
  then
    echo "file permissions ok"
  else
    echo "please check permissions on this file. it should be 700."
    exit 1
  fi

}



check_aurora() {
  timestamp
  echo -n "check if there is a working tos aurora installation.. "
  tosver=`/usr/local/bin/tos version | grep Aurora`

  if [ $? -ne 0 ]
  then
    echo "no TOS Aurora installation found, exiting."
    exit 1
  else
    echo "TOS Aurora found"
  fi
}


check_bup_status() {
  timestamp
  echo -n "check if backup was completed successfully.. "

  failedjobs=`/usr/local/bin/tos backup list | grep "Status" | grep -v "Completed"`

  #echo "failedjobs content: $failedjobs"

  if [[ -z $failedjobs ]]
  then
    echo "success"
  else
    echo "some jobs failed."
    echo 'please check the output of "tos backup list" and repair accordingly.'
    echo "$failedjobs"
  # /usr/local/bin/tos backup list | sendmail -f sender@domain.test -s "Tufin backup failed" recipient@domain.test
    exit 1
  fi
}


export_bup() {
timestamp
echo -n "exporting current backups.. "
tos backup export 2> /var/log/send-backup-export.log
bupfile=`cat /var/log/send-backup-export.log | grep "file:" | awk '{print $8}' | cut -d '"' -f1`
echo "done, backup was exported to $bupfile"
}


upload_bup() {
timestamp
echo "now going to upload backup to remote host."
scp $bupfile tufin-admin@localhost:/opt/tufin/backups/test/

timestamp
if [ $? -ne 0 ]
then
  echo "ERROR: problem encountered during upload"
  exit 1
else
  echo "COMPLETE: uploaded successfully"
fi
}


cleanup() {
  timestamp
  echo -n "performing cleanup.. "
  todelete=`find /opt/tufin/backups/ -type f -mtime +3`

  if [[ -z $todelete ]]
  then
    echo "nothing to delete"
  else
    echo "these files will be deleted:"
    echo "$todelete"
    find /opt/tufin/backups/ -type f -mtime +3 -delete
  fi
}


check_perm
check_aurora
check_bup_status
export_bup
upload_bup
cleanup


timestamp
echo "finished"
