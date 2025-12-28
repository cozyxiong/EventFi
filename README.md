# EventFi
This project implements an EventFi ecosystem combining NFT with a tokenized reward system (CXC tokens) and a USDT redemption pool. The system includes:
- NFT-based event participation
- CXC token distribution through airdrops and purchases
- USDT redemption pool with vesting periods
- Governance mechanisms for fund allocation

## Build
```shell
$ forge build
```

## Env
```shell
Get-Content .env | ForEach-Object {
    if ($_ -match "^\s*([^#]\S+)\s*=\s*(.*)\s*$") {
        $varName = $matches[1]
        $varValue = $matches[2] -replace '^"|"$|^''|''$'  # 去除可能的引号
        Set-Item -Path "env:$varName" -Value $varValue
    }
}

echo $env:PRIVATE_KEY
echo $env:RPC_URL
```

## Deploy
```shell
forge script ./script/EventFiFoundry1.s.sol:EventFiFoundryScript --rpc-url $env:RPC_URL --private-key $env:PRIVATE_KEY --broadcast
```

## Address
```
token proxy contract deployed at: 0x41e8D8907F5aFaa2C6D59Db98d780441028a168e
redemption proxy contract deployed at: 0xEFD277ec5B0AE6ff23D84Dd6dCdC853055c5B288
trade proxy contract deployed at: 0xd6784eC1712fb281C5E3146AdC576b1DA92642f9
nft proxy contract deployed at: 0xD036DC573107174AA2b23499d959D7f7868DE5b3
event proxy contract deployed at: 0x485Ef19Dc852FA08f6Cd46f7c24b10A9d817D348
```
