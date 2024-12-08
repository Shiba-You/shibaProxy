## 参考
# - https://qiita.com/koinunopochi/items/091dd3fe111dd37c328c

# clientサーバで以下を実行
sudo vi /etc/systemd/resolved.conf 
```/etc/systemd/resolved.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file, or by creating "drop-ins" in
# the resolved.conf.d/ subdirectory. The latter is generally recommended.
# Defaults can be restored by simply deleting this file and all drop-ins.
#
# Use 'systemd-analyze cat-config systemd/resolved.conf' to display the full config.
#
# See resolved.conf(5) for details.

[Resolve]
# Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
# Cloudflare: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
# Google:     8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
# Quad9:      9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
DNS=<DNSサーバのIPアドレス>
#FallbackDNS=
Domains=~.
#DNSSEC=no
#DNSOverTLS=no
#MulticastDNS=no
#LLMNR=no
#Cache=yes
#CacheFromLocalhost=no
#DNSStubListener=yes
#DNSStubListenerExtra=
#ReadEtcHosts=yes
#ResolveUnicastSingleLabel=no
```

# 以降はDNSサーバで実行
# パッケージのアップデート
sudo yum update -y

# BINDのインストール
sudo yum install bind -y

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
        listen-on           port 53 { 127.0.0.1; <DNSサーバのPrivateIPアドレス> };
        listen-on-v6        port 53 { ::1; };
        directory           "/var/named";
        dump-file           "/var/named/data/cache_dump.db";
        statistics-file     "/var/named/data/named_stats.txt";
        memstatistics-file  "/var/named/data/named_mem_stats.txt";
        secroots-file       "/var/named/data/named.secroots";
        recursing-file      "/var/named/data/named.recursing";
        # すべて許可する設定。EC2のセキュリティーグループでアクセスは制限する
        allow-query         { localhost; 10.0.0.0/8; };

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


# bindの起動&自動起動の設定
sudo systemctl restart named

