if [ $# -eq 0 ]
then pg_dump -U postgres tresorier > /home/erica/backup/$(date +"%Y-%m-%d-%T")_backup.sql
else $1/bin/pg_dump -U postgres tresorier > /home/erica/backup/$(date +"%Y-%m-%d-%T")_backup.sql
fi
