# LegacyCore Agent

LegacyCore Agent is a lightweight HTTP API service for wallet management in the LegacyCoin ecosystem. It provides seed phrase generation, wallet restore, and wallet information retrieval.

## Quick Start

```bash
docker compose up -d
```

The service starts on port `8443` by default. Configuration is via environment variables (see `.env`).

## Configuration

| Variable | Default | Description |
|---|---|---|
| `LEGACYCOIN_PORT` | `8443` | API listen port |
| `LEGACYCOIN_HOST` | `0.0.0.0` | API listen host |
| `LEGACYCOIN_DATADIR` | `/data` | Wallet data directory |

## API Endpoints

| Endpoint | Description |
|---|---|
| `POST /api/generate-seed` | Generate a new wallet, return mnemonic phrase and addresses |
| `POST /api/restore-wallet` | Restore a wallet from mnemonic phrase |
| `GET /api/wallet/{name}` | Get wallet info (mnemonic, addresses, HD status) |
| `GET /api/wallets` | List all wallets |

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

### GET /api/wallet/{name}

Returns wallet info including mnemonic, all addresses, and HD derivation state.

### GET /api/wallets

Returns a list of all wallet names stored on disk.

## Build from Source

Requires Go 1.26+ and the `legacycore` repository alongside this one:

```
/app/legacycoreagent/
/app/legacycore/
```

```bash
cd /app/legacycore
go build -o /app/legacycoreagent/legacycoreagent ./cmd/legacycoreagent/
```

## Docker

```bash
docker build -f Dockerfile -t legacycoreagent ../legacycore
docker run -p 8443:8443 legacycoreagent
```

Or with docker compose:

```bash
docker compose up -d
```
