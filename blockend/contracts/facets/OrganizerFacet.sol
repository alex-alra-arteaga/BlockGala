// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AppStorage} from "../libraries/AppStorage.sol";
import {Errors} from "../libraries/Errors.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import {Events} from "../libraries/Events.sol";
import {DataTypes as Types} from "../libraries/DataTypes.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Constants} from "../libraries/Constants.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract OrganizerFacet is Modifiers {
    using Clones for address;
    // Registry logic for corporation wanting to use the platform

    /**
     * @notice Register a subscription
     */
    function registerSubscription(
        uint16 subscriptionId,
        Types.SubscriptionConfig memory config,
        uint mevDeadline
    ) external onlyDiamond isSubscriptionCreated(subscriptionId) {
        // Register a subscription
        uint16 nextSubscriptionId = uint16(s.numOfSubscriptions + 1);
        Types.Subscription storage newSubscription = s.subscriptions[
            nextSubscriptionId
        ];
        newSubscription.startTime = block.timestamp;
        newSubscription.creator = config.creator;
        newSubscription.deadline = config.deadline;
        newSubscription.eventCreditsPromised = config.eventCreditsPromised;
        newSubscription.organizationName = config.organizationName;
        newSubscription.name = config.name;
        newSubscription.description = config.description;

        // prevent function execution if mevDeadline is not met
        require(mevDeadline > block.timestamp + 2 hours);
        require(nextSubscriptionId == subscriptionId);

        cloneOrganizerVault(subscriptionId);

        unchecked {
            s.numOfSubscriptions++;
        }
    }
    /**
    * @notice propose a name and description change for a subscription
    * @dev Has a timelock to prevent misuse without users being warned in a timely manner
    */
    function proposeNameDescriptionChange(
        string memory newName,
        string memory newDescription,
        uint16 subscriptionId
    ) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
        // Propose a name and description change
        if (
            keccak256(abi.encode(s.subscriptions[subscriptionId].name)) ==
            keccak256(abi.encode(newName))
        ) revert Errors.NameMustBeDifferent();
        if (
            keccak256(
                abi.encode(s.subscriptions[subscriptionId].description)
            ) == keccak256(abi.encode(newDescription))
        ) revert Errors.DescriptionMustBeDifferent();

        s.subscriptions[subscriptionId].timeLockFunc.name = newName;
        s.subscriptions[subscriptionId].timeLockFunc.description = newDescription;

        emit Events.NameDescriptionChangeProposed(
            subscriptionId,
            newName,
            newDescription
        );
    }

    //function cancelSubscription(
    //    uint16 subscriptionId
    //) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
    //    // Cancel a subscription
    //    // if it is unabled without meeting deadlines, a % of the subscription time lift
    //    // and event credits left will compute the money the org has to pay back to users
    //    if (s.subscriptions[subscriptionId].deadline == 0)
    //        revert Errors.SubscriptionNotInitialized(subscriptionId);

    //    s.subscriptions[subscriptionId].isCanceled = true;
    //}

    function changeName(
        string memory newName,
        uint16 subscriptionId
    ) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
        // Change the name of a subscription
        if (keccak256(abi.encode(s.subscriptions[subscriptionId].timeLockFunc.name)) != keccak256(abi.encode(newName))) revert Errors.NameMustBeDifferent();

        uint deadlineToModify = s.subscriptions[subscriptionId].timeLockFunc.time;
        if (deadlineToModify < block.timestamp) revert Errors.TimeLockNotMet();
        s.subscriptions[subscriptionId].name = newName;

        emit Events.NameChanged(subscriptionId, newName);
    }

    function changeDescription(
        string memory newDescription,
        uint16 subscriptionId
    ) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
        // Change the description of a subscription
        uint deadlineToModify = s.subscriptions[subscriptionId].timeLockFunc.time;
        if (deadlineToModify < block.timestamp) revert Errors.TimeLockNotMet();
        s.subscriptions[subscriptionId].description = newDescription;

        emit Events.DescriptionChanged(subscriptionId, newDescription);
    }

    function extendDeadline(
        uint newDeadline,
        uint16 subscriptionId
    ) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
        // Extend the deadline of a subscription
        if (s.subscriptions[subscriptionId].deadline <= newDeadline)
            revert Errors.DeadlineMustBeGreaterThanPrevious();
        s.subscriptions[subscriptionId].deadline = newDeadline;
    }

    function incrementPromisedEventCredits(
        uint16 subscriptionId,
        uint newAmount
    ) external onlyDiamond onlySubscriptionCreator(subscriptionId) {
        // Increment event credits
        if (s.subscriptions[subscriptionId].eventCreditsPromised <= newAmount)
            revert Errors.EventCreditsMustBeGreaterThanPrevious();
        s.subscriptions[subscriptionId].eventCreditsPromised = newAmount;
    }

    /**
     * @dev Clone the organizer vault for managing DAO or any other utility for subscriptors
     */
    function cloneOrganizerVault(uint16 subscriptionId) private {
        address newOrganizerVault = Constants.ORGANIZER_VAULT_IMPLEMENTATION.clone();
        uint codeSize;

        assembly {
          codeSize := extcodesize(newOrganizerVault)
        }
        
        if (newOrganizerVault == address(0) || codeSize == 0) revert Errors.CloneFailed();

        s.subscriptions[subscriptionId].organizerVault = IERC4626(newOrganizerVault);
    }
}
