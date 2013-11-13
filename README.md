#Deploy info
1. install postgresql & fix config/database.yml 
2. install redis-server
3. rake db:create (test db connection is success)
4. rake db:migrate (would have error at the end)
5. rake db:seed (input initial data)
6. add line "127.0.0.1 www.airesis.it" to /etc/hosts
7. use www.airesis.it:3000 to dev
