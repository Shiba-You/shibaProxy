## 参考
# - https://qiita.com/koinunopochi/items/091dd3fe111dd37c328c

# パッケージのアップデート
sudo yum update -y

# BINDのインストール
sudo yum install bind -y

# originalファイルとのコピーと保存
sudo cp /etc/named.conf{,.original}

# confファイルの編集
sudo vi /etc/named.conf
```/etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
        # listen-on port 53 { 127.0.0.1; };
        # DNSサーバが待機するIPアドレスとポートを設定する
        listen-on           port 53 { 127.0.0.1; [EC2のPrivateIPアドレスを設定する] }; #TODO: ec2のprivate ipを設定
        listen-on-v6        port 53 { ::1; };
        directory           "/var/named";
        dump-file           "/var/named/data/cache_dump.db";
        statistics-file     "/var/named/data/named_stats.txt";
        memstatistics-file  "/var/named/data/named_mem_stats.txt";
        secroots-file       "/var/named/data/named.secroots";
        recursing-file      "/var/named/data/named.recursing";
        # すべて許可する設定。EC2のセキュリティーグループでアクセスは制限する
        allow-query         { any; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        # リクエストされたドメイン名がローカルzoneにない場合に、ほかのDNSサーバに問い合わせることを許可する
        recursion           yes;

        # DNSSECが有効なゾーンからの応答に対して、署名の添付や検証する準備を行う
        dnssec-enable       yes;
        
        # DNSSEC署名が有効かどうかを検証する機能の有効化
        dnssec-validation   yes;

        # サーバが解決できないクエリをフォワーダー（上流のDNS）に転送する際のIPを指定する
        forwarders          { 8.8.8.8; 8.8.4.4; };
        
        # 解決できない場合は転送して、自身は再帰的な問い合わせを行わない
        forward             only;

        managed-keys-directory "/var/named/dynamic";

        pid-file            "/run/named/named.pid";
        session-keyfile     "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include             "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};
# example.comに対するDNSクエリが来た場合に、原本をもつサーバ（type:master）として、
# master.example.comに基づいて適切な処理を行う
zone "example.com" IN {
  type master;
  file "master.example.com";
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

# ゾーンファイルの作成
sudo vi /var/named/master.example.com
```/var/named/master.exmaple.com
$TTL 43200
@       IN      SOA     help.example.com. ns01.example.com. (
                            1          ; serial
                            21600      ; refresh (6 hours)
                            7200       ; retry (2 hours)
                            1209600    ; expire (2 weeks)
                            43200 )    ; minimum (12 hours)

        IN      NS      ns01.example.com.

ns01    IN      A       [EC2インスタンスのPrivateIP]
www     IN      A       [EC2インスタンスのPrivateIP]
```

# bindの起動&自動起動の設定
sudo systemctl start named
sudo systemctl enable named

