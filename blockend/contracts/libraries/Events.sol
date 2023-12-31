// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library Events {
    event NameChanged(uint16 indexed subscriptionId, string name);
    event DescriptionChanged(uint16 indexed subscriptionId, string description);
    event SubscriptionClaimed(
        uint16 indexed subscriptionId,
        address indexed claimer,
        uint256 indexed amount
    );
    event NameDescriptionChangeProposed(
        uint16 indexed subscriptionId,
        string newName,
        string newDescription
    );
}
