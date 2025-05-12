// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IEvent {
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
    ) external returns (uint256);
    function endEvent(uint256 eventId) external returns (bool);
    function eventAirdrop(uint256 eventId, address account, uint256 dropAmount) external returns (bool);
}
