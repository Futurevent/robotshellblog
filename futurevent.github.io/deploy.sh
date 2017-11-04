hexo generate
cp -r public/* ~/code/futurevent
cd ~/code/futurevent
git pull
git add .
git commit -m "update blog"
git push origin master
