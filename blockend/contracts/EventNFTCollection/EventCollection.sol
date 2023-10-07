// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ClonableERC721 } from "blockend/contracts/utils/ClonableERC721.sol";

error CallerNotDiamond();

contract EventCollection is ClonableERC721 {
    address public diamondAddress;
    string baseURI;

    modifier onlyDiamond() {
        if (diamondAddress != msg.sender) revert CallerNotDiamond();
        _;
    }

    constructor () {
        diamondAddress = msg.sender;
    }
    /**
     * @dev No need for initializer, super.initialize already has it
     */
    function intialize(string memory name, string memory symbol, string memory description) public {
        super.initialize(name, symbol, description);
    }

    function mint(address to, uint256 quantity) external onlyDiamond {
        _mint(to, quantity);
    }

    function changeBaseUri(string memory _newBaseURI) external onlyDiamond {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}