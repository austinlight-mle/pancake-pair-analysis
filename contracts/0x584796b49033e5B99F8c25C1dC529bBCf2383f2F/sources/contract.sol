// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleProxy111222 {


    bytes32 private constant _OWNER_SLOT =
        0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

    bytes32 private constant _IMPL_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event ImplementationSet(address indexed implementation);
    event OwnershipRenounced();

    modifier onlyOwner() {
        require(_getOwner() == msg.sender, "Not owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view returns (address) {
        return _getOwner();
    }

    function implementation() public view returns (address) {
        return _getImpl();
    }

    function setImplementation(address _implementation) external onlyOwner {
        require(_implementation != address(0), "Zero address");
        require(_getImpl() == address(0), "Already set");
        _setImpl(_implementation);
        emit ImplementationSet(_implementation);
    }

    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
        emit OwnershipRenounced();
    }

    function _getOwner() internal view returns (address o) {
        bytes32 slot = _OWNER_SLOT;
        assembly { o := sload(slot) }
    }

    function _setOwner(address o) internal {
        bytes32 slot = _OWNER_SLOT;
        assembly { sstore(slot, o) }
    }

    function _getImpl() internal view returns (address o) {
        bytes32 slot = _IMPL_SLOT;
        assembly { o := sload(slot) }
    }

    function _setImpl(address o) internal {
        bytes32 slot = _IMPL_SLOT;
        assembly { sstore(slot, o) }
    }

    fallback() external payable {
        address impl = _getImpl();
        require(impl != address(0), "Implementation not set");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        address impl = _getImpl();
        require(impl != address(0), "Implementation not set");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}