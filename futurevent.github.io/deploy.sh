hexo generate
cd ../../futurevent
git pull
cd -
cp -r public/* ../../futurevent
cd ../../futurevent
git add -A .
git commit -m "update blog"
git push origin master
