function FindProxyForURL(url, host) {
  // ローカルネットワークは直接接続
  if (
    isInNet(host, "192.168.0.0", "255.255.255.0") ||
    dnsDomainIs(host, ".local")
  ) {
    return "DIRECT";
  }

  // プロキシサーバへは直接接続
  if (dnsDomainIs(host, ".compute.amazonaws.com")) {
    return "DIRECT";
  }

  // その他の通信は標準プロキシを使用
  return "PROXY ec2-54-178-58-251.ap-northeast-1.compute.amazonaws.com:3128; DIRECT"; // フェイルオーバー時に直接通信
}
