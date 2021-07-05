#!/bin/sh

set -e

cd /var/www/html/repbl
yarn install

gem update --system
gem update rake
bundle update

echo "Waiting for mysql"

while ! mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" --silent; do
    sleep 1
done

>&2 echo "MySQL is up - executing command"

bundle exec rake db:migrate
bundle exec rake assets:precompile
bundle exec rake repo:insert[https://github.com/wasuken/nippo/archive/master.zip,nippo]
bundle exec rails s
