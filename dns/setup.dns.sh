## 参考
# - https://qiita.com/koinunopochi/items/091dd3fe111dd37c328c
# systemd-resolved の停止
sudo systemctl status systemd-resolved
sudo systemctl disable systemd-resolved 

# clientでの名前解決禁止
sudo vi /etc/resolv.conf
```/etc/resolv.conf
#This is /run/systemd/resolve/resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients directly to
# all known uplink DNS servers. This file lists all configured search domains.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

# nameserver 10.0.0.2                           # コメントアウトした
# search ap-northeast-1.compute.internal        # コメントアウトした
```

# proxyサーバで実行
sudo vi /etc/squid/squid.conf
```
#
# Recommended minimum configuration:
#

# Example rule allowing access from your local networks.
# Adapt to list your (internal) IP networks from where browsing
# should be allowed
acl localnet src 0.0.0.1-0.255.255.255  # RFC 1122 "this" network (LAN)
acl localnet src 10.0.0.0/8             # RFC 1918 local private network (LAN)
acl localnet src 100.64.0.0/10          # RFC 6598 shared address space (CGN)
acl localnet src 169.254.0.0/16         # RFC 3927 link-local (directly plugged) machines
acl localnet src 172.16.0.0/12          # RFC 1918 local private network (LAN)
acl localnet src 192.168.0.0/16         # RFC 1918 local private network (LAN)
acl localnet src fc00::/7               # RFC 4193 local private network range
acl localnet src fe80::/10              # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http

#
# Recommended minimum Access Permission configuration:
#
# Deny requests to certain unsafe ports
http_access deny !Safe_ports

# Deny CONNECT to other than secure SSL ports
http_access deny CONNECT !SSL_ports

# Only allow cachemgr access from localhost
http_access allow localhost manager
http_access deny manager

# This default configuration only allows localhost requests because a more
# permissive Squid installation could introduce new attack vectors into the
# network by proxying external TCP connections to unprotected services.
http_access allow localhost

# The two deny rules below are unnecessary in this default configuration
# because they are followed by a "deny all" rule. However, they may become
# critically important when you start allowing external requests below them.

# Protect web applications running on the same server as Squid. They often
# assume that only local users can access them at "localhost" ports.
http_access deny to_localhost

# Protect cloud servers that provide local users with sensitive info about
# their server via certain well-known link-local (a.k.a. APIPA) addresses.
http_access deny to_linklocal

#
# INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
#

# For example, to allow access from your local networks, you may uncomment the
# following rule (and/or add rules that match your definition of "local"):
http_access allow localnet

# And finally deny all other access to this proxy
http_access deny all

# Squid normally listens to port 3128
http_port 3128

# Uncomment and adjust the following to add a disk cache directory.
#cache_dir ufs /var/spool/squid 100 16 256

# Leave coredumps in the first cache dir
coredump_dir /var/spool/squid

dns_nameservers 10.0.20.161                       # 追記

#
# Add any of your own refresh_pattern entries above these.
#
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

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

