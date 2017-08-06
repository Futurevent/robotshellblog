hexo generate
cp -r public/* ~/code/futurevent
cd ~/code/futurevent
git add .
git commit -m "update blog"
git push origin master
