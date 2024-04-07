git config --global user.email "you.tian@sunmi.com"
git config --global user.name "CaoRuis"
# 解决文件路径过长问题
git config --global core.longpaths true
# 解决git中文乱码
git config --global core.quotepath false
# 以UTF-8格式编码提交信息
git config --global i18n.commitEncoding utf-8
# 自动转化文本文件换行符为lf
git config --global core.eol lf
git config --global core.autocrlf input
git config --global core.safecrlf warn
# 空格检查
git config --global core.whitespace trailing-space,space-before-tab,-cr-at-eol
# 开启git颜色
git config --global color.ui true
# tag排序
git config --global tag.sort version:refname
# 以iso格式显示日志
git config --global log.date iso
# git pull强制使用rebase而非merge，效果等同于--rebase=true
# 更新代码时推荐使用git pull --prune --progress --tags --rebase=true --autostash
git config --global pull.rebase true
# rebase时自动执行stash，rebase结束后自动将该stash弹出，效果等同于--autostash
git config --global rebase.autosquash true
# git pull存在merge行为时禁止自动生成merge提交，强制用户使用-rebase进行代码同步
# git config --global merge.ff only
# merge时忽略行尾换行符比较
git config --global merge.renormalize true
 