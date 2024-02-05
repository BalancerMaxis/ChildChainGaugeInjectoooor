// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ConfirmableOwnable is Ownable {
    address public proposedOwner;
    event OwnershipTransferProposed(address indexed previousOwner, address indexed newOwner);


    modifier onlyProposedOwner() {
        require(msg.sender == proposedOwner, "Not proposed owner");
        _;
    }

    function proxyProposeFirstOwner(address _initialOwner) public  {
        require(_initialOwner != address(0), "Invalid initial owner");
        require(proposedOwner == address(0), "Initial Owner Already Set");
        proposedOwner = _initialOwner;
    }

    function proposeOwnershipTransfer(address _proposedOwner) external onlyOwner {
        require(_proposedOwner != address(0), "Invalid proposed owner");
        require(_proposedOwner != owner(), "Already owner");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner(), _proposedOwner);
    }

    function confirmOwnershipTransfer() external onlyProposedOwner {
        emit OwnershipTransferred(owner(), proposedOwner);
        _transferOwnership(proposedOwner);
        proposedOwner = address(0);
    }

    function cancelOwnershipTransfer() external onlyOwner {
        emit OwnershipTransferProposed(owner(), address(0));
        proposedOwner = address(0);
    }
}
