# localのPCからbastionサーバに接続 （bastionとclientが同じkey-pairを利用している前提）
ssh -A ec2-user@<踏み台サーバのパブリックIP>

# bastionサーバ