// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AppStorage} from "./AppStorage.sol";
import {Errors} from "./Errors.sol";

contract Modifiers {
    AppStorage internal s;

    modifier onlyDiamond() {
        if (
            msg.sender != address(this))
            revert Errors.CallerCanOnlyBeDiamond(msg.sender, address(this));
        _;
    }

    modifier onlySubscriptionCreator(uint16 subscriptionId) {
        if (s.subscriptions[subscriptionId].creator != msg.sender)
            revert Errors.CallerNotSubscriptionCreator(msg.sender, subscriptionId);
        _;
    }

    modifier isSubscriptionValid(uint16 subscriptionId) {
        if (s.subscriptions[subscriptionId].deadline == 0)
            revert Errors.SubscriptionNotInitialized(subscriptionId);
        if (s.subscriptions[subscriptionId].isCanceled)
            revert Errors.SubscriptionCanceled(subscriptionId);
        _;
    }

    modifier isSubscriptionCreated(uint16 subscriptionId) {
        if (s.subscriptions[subscriptionId].deadline != 0)
            revert Errors.SubscriptionAlreadyCreated(subscriptionId);
        _;
    }

    modifier onlySubscriptors(uint16 subscriptionId) {
        if (!s.subscribers[msg.sender].isSubscriber[subscriptionId]) revert Errors.CallerNotSubscriptor(msg.sender);
        _;
    }

    modifier isEventCreditIdValid(uint16 subscriptionId, uint256 eventCreditId) {
        if (s.subscriptions[subscriptionId].eventCredits[eventCreditId].subscriptionId == 0)
            revert Errors.EventCreditIdNotValid(subscriptionId, eventCreditId);
        _;
    }
}