// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {INft} from "../interface/INft.sol";

contract EventStorage {
    struct EventRecord {
        uint256 eventId;
        address eventInitializer;
        string eventTitle;
        string eventContent;
        string eventLocation;
        uint256 eventStartTime;
        uint256 eventEndTime;
        uint256 totalDropAmount;
        uint256 totalDropNumber;
        uint256 minDropAmount;
        uint256 maxDropAmount;
        address dropTokenType;
    }
    struct EventInfo {
        uint256 eventId;
        uint256 alreadyDropAmount;
        uint256 alreadyDropNumber;
        uint256 rewardTokenAmount;
        bool status;
    }
    struct DropInfo {
        uint256 eventId;
        address account;
        uint256 dropTime;
        address dropTokenType;
        uint256 dropTokenAmount;
    }
    EventRecord[] public eventRecords;
    EventInfo[] public eventInfos;
    DropInfo[] public dropInfos;
    INft public iNft;
    uint256 public maxEventPeriod = 30 days;
    uint256 public constant eventPoolSupply = (100_000_000 * 1e6 * 4) / 10;
    uint256 public constant minimumDropAmount = 1e6;
    uint256 public totalMinedAmount;
    mapping(address => uint256) public lastRewardTime;
    mapping(uint256 => mapping(address => bool)) public isEventDropGained;
}
