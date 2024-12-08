# localのPCからbastionサーバに接続 （bastionとclientが同じkey-pairを利用している前提）
# ssh-agent にローカルに保存されている秘密鍵を追加する
eval "$(ssh-agent -s)"
ssh-add <秘密鍵へのパス>
ssh -A ec2-user@<bastionサーバのパブリックIPv4DNS> -t ssh ec2-user@<転送先のプライベートIPDNS名>

# bastionサーバ