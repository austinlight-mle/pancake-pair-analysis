#!/usr/bin/env python3
"""
Scan PancakeSwap V2 pair contracts from most recent to oldest,
filter by USD liquidity, and output qualifying contracts to
pair_contracts.txt (full BscScan URLs), contracts.json (detailed info),
and new_tokens.txt (addresses of new tokens, excluding WBNB/USDT).

Usage:
    python pancake_pair_scan.py                                          # scan all pairs (recent first)
    python pancake_pair_scan.py --limit 500                              # scan only the latest 500 pairs
    python pancake_pair_scan.py --index 123456                           # scan a single pair at index 123456
    python pancake_pair_scan.py --start-index 100000                     # start from pair index 100000
    python pancake_pair_scan.py --end-index 50000                        # stop at pair index 50000
    python pancake_pair_scan.py --start-index 100000 --end-index 99000   # scan a specific range
    python pancake_pair_scan.py --min-liq 50000                          # set minimum liquidity to $50,000
    python pancake_pair_scan.py --threads 8                              # use 8 worker threads (default: 4)
    python pancake_pair_scan.py --max-retries 10                         # max retries per call (default: 5)
"""

import argparse
import json
import os
import sys
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from web3 import Web3
from datetime import datetime, timezone

FACTORY_ADDRESS = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"

FACTORY_ABI = [
    {"inputs": [], "name": "allPairsLength", "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "stateMutability": "view", "type": "function"},
    {"inputs": [{"internalType": "uint256", "name": "", "type": "uint256"}], "name": "allPairs", "outputs": [{"internalType": "address", "name": "", "type": "address"}], "stateMutability": "view", "type": "function"},
]

PAIR_ABI = [
    {"inputs": [], "name": "token0", "outputs": [{"internalType": "address", "name": "", "type": "address"}], "stateMutability": "view", "type": "function"},
    {"inputs": [], "name": "token1", "outputs": [{"internalType": "address", "name": "", "type": "address"}], "stateMutability": "view", "type": "function"},
    {"inputs": [], "name": "getReserves", "outputs": [{"internalType": "uint112", "name": "_reserve0", "type": "uint112"}, {"internalType": "uint112", "name": "_reserve1", "type": "uint112"}, {"internalType": "uint32", "name": "_blockTimestampLast", "type": "uint32"}], "stateMutability": "view", "type": "function"},
]

ERC20_ABI = [
    {"inputs": [], "name": "decimals", "outputs": [{"internalType": "uint8", "name": "", "type": "uint8"}], "stateMutability": "view", "type": "function"},
    {"inputs": [], "name": "symbol", "outputs": [{"internalType": "string", "name": "", "type": "string"}], "stateMutability": "view", "type": "function"},
    {"inputs": [], "name": "name", "outputs": [{"internalType": "string", "name": "", "type": "string"}], "stateMutability": "view", "type": "function"},
]

DEXSCREENER_PAIRS_URL = "https://api.dexscreener.com/latest/dex/pairs/bsc/{}"
DEXSCREENER_TOKENS_URL = "https://api.dexscreener.com/tokens/v1/bsc/{}"
BSCSCAN_ADDRESS_URL = "https://bscscan.com/address/{}"
DEFAULT_MIN_LIQUIDITY = 10_000
DEFAULT_THREADS = 4
DEFAULT_MAX_RETRIES = 5
RETRY_INTERVAL = 0.5

KNOWN_BASE_TOKENS = {
    "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",  # WBNB
    "0x55d398326f99059ff775485246999027b3197955",  # USDT
}

_w3_instances: dict = {}
_w3_lock = threading.Lock()


def load_rpcs(path: str = "rpcs.txt") -> list[str]:
    if not os.path.exists(path):
        print(f"Error: {path} not found")
        sys.exit(1)
    rpcs = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                rpcs.append(line)
    if not rpcs:
        print(f"Error: No RPC URLs found in {path}")
        sys.exit(1)
    return rpcs


def get_w3(rpc_url: str) -> Web3:
    with _w3_lock:
        if rpc_url not in _w3_instances:
            _w3_instances[rpc_url] = Web3(Web3.HTTPProvider(rpc_url))
        return _w3_instances[rpc_url]


def rpc_call_with_retry(rpcs: list[str], call_fn, max_retries: int = DEFAULT_MAX_RETRIES):
    """Call call_fn(w3), cycling through rpcs on each failure."""
    last_exc: Exception | None = None
    for attempt in range(max_retries):
        rpc_url = rpcs[attempt % len(rpcs)]
        try:
            return call_fn(get_w3(rpc_url))
        except Exception as e:
            last_exc = e
            time.sleep(RETRY_INTERVAL)
    raise last_exc or RuntimeError("All RPC retries exhausted")


def http_get_with_retry(url: str, max_retries: int = DEFAULT_MAX_RETRIES, timeout: int = 10) -> requests.Response:
    last_exc: Exception | None = None
    for _ in range(max_retries):
        try:
            resp = requests.get(url, timeout=timeout)
            resp.raise_for_status()
            return resp
        except Exception as e:
            last_exc = e
            time.sleep(RETRY_INTERVAL)
    raise last_exc or RuntimeError(f"HTTP GET failed: {url}")


def get_token_price_usd(address: str, cache: dict, cache_lock: threading.Lock, max_retries: int) -> float | None:
    addr_lower = address.lower()
    with cache_lock:
        if addr_lower in cache:
            return cache[addr_lower]
    result = None
    try:
        resp = http_get_with_retry(DEXSCREENER_TOKENS_URL.format(address), max_retries)
        pairs = resp.json()
        if isinstance(pairs, list) and pairs:
            price = pairs[0].get("priceUsd")
            if price is not None:
                result = float(price)
    except Exception:
        pass
    with cache_lock:
        cache[addr_lower] = result
    return result


def query_pair_dexscreener(pair_address: str, max_retries: int) -> dict | None:
    try:
        resp = http_get_with_retry(DEXSCREENER_PAIRS_URL.format(pair_address), max_retries)
        data = resp.json()
        return data.get("pair") or (data.get("pairs") or [None])[0]
    except Exception:
        return None


def calc_liquidity_from_reserves(
    rpcs: list[str], pair_address: str, price_cache: dict,
    price_cache_lock: threading.Lock, max_retries: int
) -> tuple:
    try:
        def fetch(w3):
            pair = w3.eth.contract(address=Web3.to_checksum_address(pair_address), abi=PAIR_ABI)
            t0 = pair.functions.token0().call()
            t1 = pair.functions.token1().call()
            reserves = pair.functions.getReserves().call()
            tok0 = w3.eth.contract(address=Web3.to_checksum_address(t0), abi=ERC20_ABI)
            tok1 = w3.eth.contract(address=Web3.to_checksum_address(t1), abi=ERC20_ABI)
            return (
                t0, t1, reserves,
                tok0.functions.decimals().call(),
                tok1.functions.decimals().call(),
                tok0.functions.symbol().call(),
                tok1.functions.symbol().call(),
                tok0.functions.name().call(),
                tok1.functions.name().call(),
            )

        t0, t1, reserves, dec0, dec1, sym0, sym1, name0, name1 = rpc_call_with_retry(rpcs, fetch, max_retries)

        p0 = get_token_price_usd(t0, price_cache, price_cache_lock, max_retries)
        p1 = get_token_price_usd(t1, price_cache, price_cache_lock, max_retries)

        val = 0.0
        if p0 is not None:
            val += (reserves[0] / 10**dec0) * p0
        if p1 is not None:
            val += (reserves[1] / 10**dec1) * p1

        return val, {"address": t0, "name": name0, "symbol": sym0}, {"address": t1, "name": name1, "symbol": sym1}
    except Exception:
        return None, None, None


def process_pair(
    i: int, rpcs: list[str], price_cache: dict, price_cache_lock: threading.Lock,
    min_liq: float, max_retries: int
) -> tuple:
    """Process a single pair index. Returns (i, contract_dict_or_None, status_msg)."""
    try:
        def get_addr(w3):
            factory = w3.eth.contract(address=Web3.to_checksum_address(FACTORY_ADDRESS), abi=FACTORY_ABI)
            return factory.functions.allPairs(i).call()

        pair_address = rpc_call_with_retry(rpcs, get_addr, max_retries)
    except Exception as e:
        return i, None, f"error fetching address: {e}"

    pair_data = query_pair_dexscreener(pair_address, max_retries)

    if pair_data:
        liquidity_usd = (pair_data.get("liquidity") or {}).get("usd") or 0
        base = pair_data.get("baseToken", {})
        quote = pair_data.get("quoteToken", {})
        token_a = {"address": base.get("address", ""), "name": base.get("name", ""), "symbol": base.get("symbol", "")}
        token_b = {"address": quote.get("address", ""), "name": quote.get("name", ""), "symbol": quote.get("symbol", "")}
        created_at = pair_data.get("pairCreatedAt")
        registered = datetime.fromtimestamp(created_at / 1000, tz=timezone.utc).isoformat() if created_at else ""
    else:
        liquidity_usd, token_a, token_b = calc_liquidity_from_reserves(
            rpcs, pair_address, price_cache, price_cache_lock, max_retries
        )
        if liquidity_usd is None:
            return i, None, f"{pair_address} ⏭ no data"
        registered = ""

    if liquidity_usd < min_liq:
        return i, None, f"{pair_address} ${liquidity_usd:,.0f} ⏭ below threshold"

    sym_a = (token_a or {}).get("symbol", "?")
    sym_b = (token_b or {}).get("symbol", "?")
    contract = {
        "index": i,
        "address": pair_address,
        "price_usd": round(liquidity_usd, 2),
        "token_a": token_a,
        "token_b": token_b,
        "registered": registered,
    }
    return i, contract, f"{pair_address} ${liquidity_usd:,.0f} ✓ {sym_a}/{sym_b}"


def get_new_token_address(contract: dict) -> str | None:
    addr_a = (contract.get("token_a") or {}).get("address", "").lower()
    addr_b = (contract.get("token_b") or {}).get("address", "").lower()
    a_is_base = addr_a in KNOWN_BASE_TOKENS
    b_is_base = addr_b in KNOWN_BASE_TOKENS
    if a_is_base and b_is_base:
        return None
    if a_is_base:
        return contract["token_b"]["address"]
    return contract["token_a"]["address"]


def write_outputs(contracts: list, txt_path: str, json_path: str, tokens_path: str):
    with open(txt_path, "w", encoding="utf-8") as f:
        for c in contracts:
            f.write(f"{BSCSCAN_ADDRESS_URL.format(c['address'])}\n")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(contracts, f, indent=2, ensure_ascii=False)
    with open(tokens_path, "w", encoding="utf-8") as f:
        for c in contracts:
            token_addr = get_new_token_address(c)
            if token_addr:
                f.write(f"{BSCSCAN_ADDRESS_URL.format(token_addr)}\n")


def main():
    parser = argparse.ArgumentParser(description="Scan PancakeSwap V2 pairs by liquidity")
    parser.add_argument("--limit", type=int, default=0, help="Max number of pairs to scan (0 = all)")
    parser.add_argument("--index", type=int, default=-1, help="Scan a single pair at this index")
    parser.add_argument("--start-index", type=int, default=-1, help="Start scanning from this pair index (default: latest)")
    parser.add_argument("--end-index", type=int, default=0, help="Stop scanning at this pair index, inclusive (default: 0)")
    parser.add_argument("--min-liq", type=float, default=DEFAULT_MIN_LIQUIDITY,
                        help=f"Minimum liquidity in USD (default: {DEFAULT_MIN_LIQUIDITY:,})")
    parser.add_argument("--threads", type=int, default=DEFAULT_THREADS,
                        help=f"Number of worker threads (default: {DEFAULT_THREADS})")
    parser.add_argument("--max-retries", type=int, default=DEFAULT_MAX_RETRIES,
                        help=f"Max retries per RPC/HTTP call (default: {DEFAULT_MAX_RETRIES})")
    args = parser.parse_args()

    rpcs = load_rpcs()
    print(f"Loaded {len(rpcs)} RPC URL(s) from rpcs.txt")

    def get_total(w3):
        factory = w3.eth.contract(address=Web3.to_checksum_address(FACTORY_ADDRESS), abi=FACTORY_ABI)
        return factory.functions.allPairsLength().call()

    total_pairs = rpc_call_with_retry(rpcs, get_total, args.max_retries)
    print(f"Connected to BSC | Total registered pairs: {total_pairs:,}")

    if args.index >= 0:
        start_index = min(args.index, total_pairs - 1)
        end_index = start_index
    else:
        start_index = args.start_index if args.start_index >= 0 else total_pairs - 1
        start_index = min(start_index, total_pairs - 1)
        end_index = max(args.end_index, 0)
        if args.limit > 0:
            end_index = max(start_index - args.limit + 1, end_index)

    scan_count = start_index - end_index + 1
    min_liq = args.min_liq
    threads = args.threads
    max_retries = args.max_retries

    print(
        f"Scanning index {start_index:,} → {end_index:,} ({scan_count:,} pairs) | "
        f"Min liq: ${min_liq:,.0f} | Threads: {threads} | Max retries: {max_retries}\n"
    )

    contracts: list[dict] = []
    price_cache: dict = {}
    price_cache_lock = threading.Lock()
    write_lock = threading.Lock()
    txt_path = "pair_contracts.txt"
    json_path = "contracts.json"
    tokens_path = "new_tokens.txt"
    log_path = "scan.log"

    with open(log_path, "a", encoding="utf-8") as lf:
        lf.write(
            f"[{datetime.now(timezone.utc).isoformat()}] START "
            f"start_index={start_index} end_index={end_index} threads={threads}\n"
        )

    indices = list(range(start_index, end_index - 1, -1))
    completed = 0

    with ThreadPoolExecutor(max_workers=threads) as executor:
        futures = {
            executor.submit(process_pair, i, rpcs, price_cache, price_cache_lock, min_liq, max_retries): i
            for i in indices
        }

        for future in as_completed(futures):
            pair_i = futures[future]
            completed += 1
            try:
                i, contract, msg = future.result()
                print(f"[{completed}/{scan_count}] Pair #{i} {msg}")
                if contract:
                    with write_lock:
                        contracts.append(contract)
                        write_outputs(contracts, txt_path, json_path, tokens_path)
            except Exception as e:
                print(f"[{completed}/{scan_count}] Pair #{pair_i} unexpected error: {e}")

    print(f"\nDone! Found {len(contracts)} pairs with liquidity >= ${min_liq:,.0f}")
    print(f"Results saved to {txt_path}, {json_path}, and {tokens_path}")

    with open(log_path, "a", encoding="utf-8") as lf:
        lf.write(
            f"[{datetime.now(timezone.utc).isoformat()}] END "
            f"start_index={start_index} end_index={end_index} found={len(contracts)}\n"
        )


if __name__ == "__main__":
    main()
