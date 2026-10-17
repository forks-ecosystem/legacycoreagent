# LegacyCore Agent

LegacyCore Agent is a lightweight HTTP API service for wallet management in the LegacyCoin ecosystem. It provides seed phrase generation, wallet restore, wallet information retrieval, and a read-only transaction service.

## Prerequisites

This service is built from the **LegacyCore** blockchain source and requires the `legacycore` repository to be cloned next to this one:

```
/app/legacycore/       <- required (blockchain source)
/app/legacycoreagent/  <- this project
```

To install (clone + build) the LBTC/LegacyCore node, run the provided setup script:

```bash
./_git_legacycore.sh
```

This clones `https://github.com/forks-ecosystem/legacycore.git` into `/app/legacycore`
and builds `legacycoind` + `legacycoin-cli`.

## Quick Start

```bash
./_git_legacycore.sh   # once: install/clone the LegacyCore node (required)
./__rebuild.sh         # build the agent binary and (re)start the service
```

The service runs natively on the host under systemd as `legacycoreagent.service`
(not in a container), because it needs direct access to host resources:

- `/home/coin/.legacycoin` — node datadir and wallet files
- `127.0.0.1:19556` — LegacyCoin node RPC
- `127.0.0.1:8053` — signer service (LBTC/BTC withdrawals)
- `127.0.0.1:5436` — `wallet_db` (optional audit sink)

```bash
systemctl status legacycoreagent
systemctl restart legacycoreagent
journalctl -u legacycoreagent -f
```

The service listens on `127.0.0.1:8444` by default. Configuration is via
environment variables in `/app/legacycoreagent/.env` (loaded by the systemd unit
through `EnvironmentFile`).

## Configuration

| Variable | Default | Description |
|---|---|---|
| `LEGACYCOIN_PORT` | `8444` | API listen port |
| `LEGACYCOIN_HOST` | `127.0.0.1` | API listen host |
| `LEGACYCOIN_DATADIR` | `/home/coin/.legacycoin` | Wallet data directory |
| `LEGACYCOIN_RPC_URL` | `http://127.0.0.1:19556` | Node RPC endpoint |
| `LEGACYCOIN_RPC_USER` / `LEGACYCOIN_RPC_PASS` | `coin` / `coin` | Node RPC credentials |
| `LEGACYCOIN_API_KEY` | — | Required `X-Api-Key` for `POST /api/chain/{coin}/send` |
| `LEGACYCOIN_SIGNER_URL` | `http://127.0.0.1:8053` | Signer service for withdrawals |
| `LEGACYCOIN_HOT_WALLET` | `withdrawal` | Node wallet holding the LBTC hot float |
| `LEGACYCOIN_WALLET_DB_DSN` | — | Optional `wallet_db` audit sink; empty disables it |

## API Endpoints

### Wallet service

| Endpoint | Description |
|---|---|
| `POST /api/generate-seed` | Generate a new wallet, return mnemonic phrase and addresses |
| `POST /api/restore-wallet` | Restore a wallet from mnemonic phrase |
| `GET /api/wallet/{name}` | Get wallet info (mnemonic, addresses, HD status) |
| `GET /api/wallet/{name}/mnemonic` | Get the wallet mnemonic |
| `POST /api/wallet/{name}/newaddress` | Derive and return a new address |
| `GET /api/wallet/{name}/balance` | Wallet balance |
| `GET /api/wallet/{name}/balances` | Per-address balances |
| `GET /api/wallets` | List all wallets |

### Transaction service (read-only)

| Endpoint | Description |
|---|---|
| `GET /api/chain/{coin}/balance/{address}` | Address balance |
| `GET /api/chain/{coin}/utxos/{address}?minconf=N` | Address UTXOs |
| `GET /api/chain/{coin}/validate/{address}` | Validate an address |
| `GET /api/chain/{coin}/history/{address}` | Address history |
| `POST /api/chain/{coin}/estimate` | Estimate fee/change for `(from,to,amount)` |
| `POST /api/chain/{coin}/send` | Send a transaction (requires `X-Api-Key`) |

### POST /api/generate-seed

Create a new wallet with a BIP39 mnemonic phrase.

**Request:**
```json
{
  "name": "my-wallet",
  "address_count": 3
}
```

**Response:**
```json
{
  "wallet": "my-wallet",
  "mnemonic": "word1 word2 word3 ... word24",
  "seed_hex": "hex-encoded-seed",
  "classic_address": "L...",
  "addresses": ["L...", "L...", "L..."],
  "hybrid_address": "lhyb1..."
}
```

### POST /api/restore-wallet

Restore a wallet from an existing mnemonic phrase. Derives the same addresses as the original wallet.

**Request:**
```json
{
  "name": "restored-wallet",
  "mnemonic": "word1 word2 word3 ... word24",
  "address_count": 5
}
```

**Response:**
```json
{
  "wallet": "restored-wallet",
  "mnemonic": "word1 word2 word3 ... word24",
  "classic_address": "L...",
  "addresses": ["L...", "L...", "L...", "L...", "L..."],
  "hybrid_address": "lhyb1..."
}
```

## Nginx Reverse Proxy

The panel reaches the agent through nginx. On the server that hosts it, expose
the agent under the `/sv/wallet-api/` prefix inside the `server { ... }` block:

```nginx
location /sv/wallet-api/ {
    proxy_pass http://127.0.0.1:8444/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Api-Key "<LEGACYCOIN_API_KEY>";
    proxy_read_timeout 120s;
}
```

Then reload nginx:

```bash
nginx -t && systemctl reload nginx
```

## Build from Source

Requires Go 1.26+ and the `legacycore` repository alongside this one (see [Prerequisites](#prerequisites); you can install it with `_git_legacycore.sh`):

```
/app/legacycoreagent/
/app/legacycore/
```

```bash
cd /app/legacycore
go build -o /usr/local/bin/legacycoreagent ./cmd/legacycoreagent/
```

## Deployment

`/etc/systemd/system/legacycoreagent.service`:

```ini
[Unit]
Description=LegacyCore Agent
After=network-online.target docker.service legacycoind.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/app/legacycoreagent
EnvironmentFile=/app/legacycoreagent/.env
ExecStart=/usr/local/bin/legacycoreagent
Restart=always
RestartSec=3
User=coin

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
systemctl daemon-reload
systemctl enable --now legacycoreagent
```
