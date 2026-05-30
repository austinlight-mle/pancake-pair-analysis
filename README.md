# Smart Contract Tools

Tools for inspecting and dumping smart contract data from BNB Chain.

## Setup

```bash
python -m venv .venv
.venv\Scripts\activate        # Windows
pip install -r requirements.txt
```

Add your BscScan API key to `.env`:

```
ETHERSCAN_API=your_api_key_here
```

Add BSC RPC URLs to `rpcs.txt`, one per line (multiple URLs provide fallback on rate limit errors):

```
https://bsc-dataseed.binance.org/
https://bsc-dataseed1.defibit.io/
```

---

## Scripts

### `pancake_pair_scan.py` — PancakeSwap Pair Scanner

Scans PancakeSwap V2 pair contracts (most recent first), filters by USD liquidity, and writes qualifying pairs to output files. Supports multi-threaded scanning with automatic RPC fallback and retry on failure.

```bash
python pancake_pair_scan.py                                          # scan all pairs (recent first)
python pancake_pair_scan.py --limit 500                              # scan only the latest 500 pairs
python pancake_pair_scan.py --index 123456                           # scan a single pair at index 123456
python pancake_pair_scan.py --start-index 100000                     # start from pair index 100000
python pancake_pair_scan.py --end-index 50000                        # stop at pair index 50000
python pancake_pair_scan.py --start-index 100000 --end-index 99000   # scan a specific range
python pancake_pair_scan.py --min-liq 50000                          # minimum liquidity threshold (default: $10,000)
python pancake_pair_scan.py --threads 8                              # worker threads (default: 4)
python pancake_pair_scan.py --max-retries 10                         # max retries per call (default: 5)
```

**Output:**
- `pair_contracts.txt` — one BscScan URL per line for each qualifying pair
- `contracts.json` — array of objects with `index`, `address`, `price_usd`, `token_a`, `token_b`, `registered`
- `new_tokens.txt` — BscScan URLs for the non-base token in each qualifying pair (excludes WBNB/USDT)
- `scan.log` — timestamped start/end entries for each scan run

---

### `dump_contract.py` — Contract Source Dumper

Dumps verified smart contract source code, ABI, compiler settings, and bytecode from any EVM chain via the Etherscan V2 API.

```bash
python dump_contract.py                                        # interactive prompt
python dump_contract.py --contract 0xADDRESS --chain bsc       # specify address & chain
python dump_contract.py --contract "https://bscscan.com/..."   # auto-detect chain from URL
python dump_contract.py --file contracts.txt                   # batch process from file
```

**Supported chains:** `eth`, `bsc`, `polygon`, `arbitrum`, `optimism`, `avalanche`, `fantom`, `base`

**Output** → `contracts/<address>/` containing `sources/`, `abi.json`, `settings.json`, `bytecode.txt`, `constructor_args.txt`
