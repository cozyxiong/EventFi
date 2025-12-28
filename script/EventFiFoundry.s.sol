// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin-foundry-upgrades/src/Upgrades.sol";

import "../src/contract/RedemptionPool.sol";
import "../src/contract/Event.sol";
import "../src/contract/Nft.sol";
import "../src/contract/Token.sol";
import "../src/contract/Trade.sol";

import "../src/contract/TokenStorage.sol";


contract EventFiFoundryScript is Script {

    RedemptionPool public redemptionPool;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address usdtAddress = vm.envAddress("USDT_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        // 1. deploy Token contract
        address tokenProxy = Upgrades.deployTransparentProxy(
            "Token.sol:Token",
            deployerAddress,
            abi.encodeWithSelector(Token.initialize.selector, deployerAddress, address(0))
        );

        // 2. deploy RedemptionPool contract
        redemptionPool = new RedemptionPool(address(tokenProxy), usdtAddress);

        // 3. deploy Trade contract
        address tradeProxy = Upgrades.deployTransparentProxy(
            "Trade.sol:Trade",
            deployerAddress,
            abi.encodeWithSelector(Trade.initialize.selector, deployerAddress, address(tokenProxy), usdtAddress, address(redemptionPool))
        );

        // 4. deploy Nft contract
        address nftProxy = Upgrades.deployTransparentProxy(
            "Nft.sol:Nft",
            deployerAddress,
            abi.encodeWithSelector(Nft.initialize.selector, deployerAddress, address(tokenProxy), usdtAddress, address(redemptionPool))
        );

        // 5. deploy Event contract
        address eventProxy = Upgrades.deployTransparentProxy(
            "Event.sol:Event",
            deployerAddress,
            abi.encodeWithSelector(Event.initialize.selector, deployerAddress, address(tokenProxy), usdtAddress, address(nftProxy))
        );

        // allocate token
        Token(address(tokenProxy)).setRedemptionPool(address(redemptionPool));
        TokenStorage.allocatePoolAddress memory pool = TokenStorage.allocatePoolAddress({
            eventPool: address(eventProxy),
            tradePool: address(tradeProxy),
            rewardPool: address(eventProxy),
            foundationPool: deployerAddress
        });
        Token(address(tokenProxy)).setAllocatePool(pool);
        Token(address(tokenProxy)).allocatePool();

        console.log("token proxy contract deployed at:", tokenProxy);
        console.log("redemption proxy contract deployed at:", address(redemptionPool));
        console.log("trade proxy contract deployed at:", tradeProxy);
        console.log("nft proxy contract deployed at:", nftProxy);
        console.log("event proxy contract deployed at:", eventProxy);

        vm.stopBroadcast();
    }
}
