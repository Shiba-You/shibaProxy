# yum の proxy を設定
sudo vi /etc/yum.conf
> proxy=http://<PROXYサーバのローカルIP>:<squidのデフォルトポート（おそらく3128）>

# http のproxyを設定
vi ~/.bashrc
> 
_PROXY=http://<PROXYサーバのローカルIP>:<squidのデフォルトポート（おそらく3128）>
export HTTP_PROXY=${_PROXY}
export HTTPS_PROXY=${_PROXY}
export http_proxy=${_PROXY}
export https_proxy=${_PROXY}