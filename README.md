＃動民主系統專案
---
本專案 fork 自 (Airesis)[http://github.com/coorasse/Airesis] 系統

#Deploy info
1. install postgresql & fix config/database.yml 
2. install redis-server
3. rake db:create (test db connection is success)
4. rake db:migrate (would have error at the end)
5. rake db:seed (input initial data)
6. add line "127.0.0.1 www.airesis.it" to /etc/hosts
7. use www.airesis.it:3000 to dev

#TODO
1. 除了首頁 CSS 都噴掉了，要調整
2. 修改界面成動民主界面
3. 或許需要一份教學文件
4. 可能要畫很多圖
