// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./EventStorage.sol";
import "../interface/INft.sol";
import "../interface/IEvent.sol";

contract Event is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, EventStorage, IEvent {

    using SafeERC20 for IERC20;
    IERC20 public token;
    IERC20 public usdt;

    event EventCreated(uint256 indexed eventId, address indexed eventInitializer, uint256 createTime, address dropTokenType, uint256 totalDropAmount);
    event EventEnded(uint256 eventId, address eventInitializer, uint256 endTime, address refundTokenType, uint256 refundAmount, uint256 mineAmount);
    event EventAirDropped(uint256 eventId, address account, uint256 dropTime, address dropTokenType, uint256 dropTokenAmount);

    constructor(){
        _disableInitializers();
    }

    function initialize(address _owner, address _tokenAddress, address _usdtAddress, address _nftContractAddress) public initializer {
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        iNft = INft(_nftContractAddress);
    }

    function createEvent(
        string memory eventTitle,
        string memory eventContent,
        string memory eventLocation,
        uint256 eventStartTime,
        uint256 eventEndTime,
        uint256 totalDropAmount,
        uint256 totalDropNumber,
        uint256 minDropAmount,
        uint256 maxDropAmount,
        address dropTokenType
    ) public returns (uint256) {
        require(eventEndTime > block.timestamp && eventEndTime - eventStartTime <= maxEventPeriod, "Event.createEvent: event time is error");
        require(minDropAmount > 0 && minDropAmount <= maxDropAmount, "Event.createEvent: drop amount is error");
        require(totalDropAmount > minimumDropAmount, "Event.createEvent: drop total amount is too small");
        require(totalDropAmount == maxDropAmount * totalDropNumber, "Event.createEvent: drop number and total amount not matched");

        require(dropTokenType == address(usdt) || dropTokenType == address(token), "Event.createEvent: drop token type is error");
        IERC20 dropToken = IERC20(dropTokenType);
        require(
            dropToken.allowance(msg.sender, address(this)) > totalDropAmount && dropToken.balanceOf(msg.sender) > totalDropAmount,
            "Event.createEvent: balance or allowance not enough"
        );
        dropToken.safeTransferFrom(msg.sender, address(this), totalDropAmount);

        EventRecord memory record = EventRecord({
            eventId: eventRecords.length + 1,
            eventInitializer: msg.sender,
            eventTitle: eventTitle,
            eventContent: eventContent,
            eventLocation: eventLocation,
            eventStartTime: eventStartTime,
            eventEndTime: eventEndTime,
            totalDropAmount: totalDropAmount,
            totalDropNumber: totalDropNumber,
            minDropAmount: minDropAmount,
            maxDropAmount: maxDropAmount,
            dropTokenType: dropTokenType
        });
        EventInfo memory info = EventInfo({
            eventId: eventRecords.length + 1,
            alreadyDropAmount: 0,
            alreadyDropNumber: 0,
            rewardTokenAmount: 0,
            status: true
        });
        eventRecords.push(record);
        eventInfos.push(info);

        emit EventCreated(record.eventId, msg.sender, block.timestamp, dropTokenType, totalDropAmount);

        return record.eventId;
    }

    function endEvent(uint256 eventId) public nonReentrant returns (bool) {
        require(eventId > 0 && eventId <= eventRecords.length, "Event.endEvent: event id is wrong");

        EventRecord memory record = eventRecords[eventId - 1];
        EventInfo memory info = eventInfos[eventId - 1];
        require(record.eventInitializer == msg.sender, "Event.endEvent: event initializer is wrong");
        require(info.status == true, "Event.endEvent: event status is wrong");
        info.status = false;

        uint256 refundAmount = record.totalDropAmount - info.alreadyDropAmount;
        if (refundAmount > 0) {
            IERC20(record.dropTokenType).safeTransfer(msg.sender, refundAmount);
        }

        uint256 mineAmount = 0;
        if (iNft.getNftExpirationTime(msg.sender) > block.timestamp && (lastRewardTime[msg.sender] == 0 || block.timestamp - lastRewardTime[msg.sender] > 24 hours)) {
            (uint8 rewardPercent, uint256 maxMineAmount) = getMiningArgs();
            if (rewardPercent == 0) { return false; }

            uint256 mineAmount1 = info.alreadyDropAmount;
            uint256 mineAmount2 = info.alreadyDropNumber * 5 * 1e6;
            mineAmount = mineAmount1 < mineAmount2 ? mineAmount1 : mineAmount2;
            mineAmount = (mineAmount * rewardPercent) / 100;
            if (mineAmount > maxMineAmount) { mineAmount = maxMineAmount; }
            if (totalMinedAmount + mineAmount > eventPoolSupply) {
                mineAmount = eventPoolSupply - totalMinedAmount;
            }

            info.rewardTokenAmount = mineAmount;
            totalMinedAmount += mineAmount;
            lastRewardTime[msg.sender] = block.timestamp;

            token.safeTransfer(msg.sender, mineAmount);
        }

        emit EventEnded(eventId, msg.sender, block.timestamp, record.dropTokenType, refundAmount, mineAmount);

        return true;
    }

    function eventAirdrop(uint256 eventId, address account, uint256 dropAmount) external nonReentrant returns (bool) {
        require(isEventDropGained[eventId][account] == false, "Event.eventDrop: this account has gained the event airdrop");

        EventRecord memory record = eventRecords[eventId - 1];
        EventInfo memory info = eventInfos[eventId - 1];

        require(record.eventInitializer == msg.sender, "Event.event: you are not this event's initializer");
        require(info.status == false, "Event.event: this event has not end");
        require(block.timestamp >= record.eventEndTime, "Event.event: this event has not reach end time");
        require(record.totalDropAmount >= info.alreadyDropAmount + dropAmount, "Event.event: this event drop amount not enough");
        require(record.totalDropNumber >= info.alreadyDropNumber + 1, "Event.event: this event drop number is exceeded");

        info.alreadyDropNumber++;
        info.alreadyDropAmount += dropAmount;
        DropInfo memory dropInfo = DropInfo({
            eventId: eventId,
            account: account,
            dropTime: block.timestamp,
            dropTokenType: record.dropTokenType,
            dropTokenAmount: dropAmount
        });
        dropInfos.push(dropInfo);

        IERC20(record.dropTokenType).safeTransfer(account, dropAmount);

        emit EventAirDropped(eventId, account, block.timestamp, record.dropTokenType, dropAmount);

        return true;
    }

    function getMiningArgs() internal view returns (uint8, uint256) {
        uint8 rewardPercent = 0;
        uint256 maxMineAmount = 0;

        if (totalMinedAmount < (eventPoolSupply * 5) / 10) {
            rewardPercent = 50;
            maxMineAmount = 60 * 1e6;
        } else if (totalMinedAmount < (eventPoolSupply * 6) / 10) {
            rewardPercent = 40;
            maxMineAmount = 50 * 1e6;
        } else if (totalMinedAmount < (eventPoolSupply * 7) / 10) {
            rewardPercent = 30;
            maxMineAmount = 25 * 1e6;
        } else if (totalMinedAmount < (eventPoolSupply * 8) / 10) {
            rewardPercent = 20;
            maxMineAmount = 12 * 1e6;
        } else if (totalMinedAmount < (eventPoolSupply * 9) / 10) {
            rewardPercent = 10;
            maxMineAmount = 6 * 1e6;
        } else {
            rewardPercent = 5;
            maxMineAmount = 3 * 1e6;
        }
        return (rewardPercent, maxMineAmount);
    }
}
