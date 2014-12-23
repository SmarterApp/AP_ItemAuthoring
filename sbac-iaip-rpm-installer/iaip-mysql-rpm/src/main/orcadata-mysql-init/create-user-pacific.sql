DELETE FROM mysql.user where user = '';
-- DELETE FROM mysql.user where user = '' or password = '';

CREATE USER 'pacific'@'localhost' IDENTIFIED BY 'itemong3r';
GRANT ALL PRIVILEGES ON *.* TO 'pacific'@'localhost';

GRANT ALL PRIVILEGES ON *.* TO 'pacific'@'%' IDENTIFIED BY 'itemong3r';

FLUSH PRIVILEGES;
