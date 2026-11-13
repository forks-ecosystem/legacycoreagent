COOKIE=$(cat /home/coin/.legacycoin/.cookie)
echo $COOKIE
curl -s --user "$COOKIE" \
  -H "Content-Type: application/json" \
  -H "X-LegacyCoin-Wallet: pool" \
  -d '{"jsonrpc":"1.0","id":1,"method":"listunspent","params":[1,9999999]}' \
  -X POST  http://127.0.0.1:19556/
