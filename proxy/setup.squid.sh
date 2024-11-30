# パッケージのアップデート
sudo yum update -y

# squidのinstlal
sudo yum install -y squid

# squidの設定ファイル設定
sudo vi /etc/squid/squid.conf
```/etc/squid/squid.conf
acl client_pc src <クライアントPCのローカルIP>  # client_pcの定義
http_access allow client_pc                 # client_pcの許可
http_access allow localnet                  # 同じサブネット内のclient用
```

# squidの再起動
sudo systemctl restart squid

# client_pcで以下を操作
# ※ 自宅のmacを想定
ssh -i <ec2のキーペア> -N -L 3128:localhost:3128 ec2-user@<ec2のパブリックIP> # sshトンネリングで、localhost:3128 <-> ec2：3128 に繋げることが可能
# macの「設定」 / 「プロキシ」 / 「Webプロキシ（HTTP）」 と 「保護されたWebプロキシ（HTTPS）」のサーバに localhost, ポートに 3128を設定（3128はsquidのデフォルト値）

# 確認
# 1. webでネットが閲覧できるか確認
# 2. ifconfig.me にアクセスして、どこからアクセスしているのか確認
curl http://ifconfig.me 
> <ec2のグローバルIP>                               # 自宅のグローバルIPではなく、ec2のグローバルIPが返ってきていればOK
# 3. squid のログを確認
sudo vi /var/log/squid/access.log