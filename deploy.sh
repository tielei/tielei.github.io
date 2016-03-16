#!/bin/bash
git pull
jekyll build
sudo cp -R _site/* /var/www/www.panxw.com
exit

