LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
repo forall -j1 -pvc 'echo -e "# ${REPO_PATH} --> ${REPO_PROJECT}"; git log --parents' 2>&1 | tee V2se-全部提交记录.log