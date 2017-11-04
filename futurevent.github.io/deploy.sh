hexo generate
cp -r public/* ../../futurevent
cd ~/code/futurevent
git pull
git add -A .
git commit -m "update blog"
git push origin master
