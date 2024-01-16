// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC7092.sol";
import "../BondStorage.sol";

contract BondMumbai is IERC7092, IERC7092CrossChain, BondStorage, CCIPReceiver  {
    constructor(
        BondData.Bond memory _bond,
        BondData.Issuer memory _issuer,
        address _routerAddress,
        address _linkTokenAddress
    ) CCIPReceiver(_routerAddress) {
        bonds = _bond;
        issuer = _issuer;

        router = IRouterClient(_routerAddress);
        linkToken = LinkTokenInterface(_linkTokenAddress);
    }

    function isin() external view returns(string memory) {
        return bonds.isin;
    }
    
    function name() external view returns(string memory) {
        return bonds.name;
    }

    function symbol() external view returns(string memory) {
        return bonds.symbol;
    }

    function currency() external view returns(address) {
        return bonds.currency;
    }

    function denomination() external view returns(uint256) {
        return bonds.denomination;
    }

    function issueVolume() external view returns(uint256) {
        return bonds.issueVolume;
    }

    function couponRate() external view returns(uint256) {
        return bonds.couponRate;
    }

    function issueDate() external view returns(uint256) {
        return bonds.issueDate;
    }

    function maturityDate() external view returns(uint256) {
        return bonds.maturityDate;
    }

    function principalOf(address _account) external view returns(uint256) {
        return _principals[_account];
    }

    function balanceOf(address _account) public view returns(uint256) {
        uint256 _principal = _principals[_account];
        uint256 _denomination = bonds.denomination;

        return _principal / _denomination;
    }

    function allowance(address _owner, address _spender) external view returns(uint256) {
        return _approvals[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;
        _approve(_owner, _spender, _amount);

        return true;
    }

    function decreaseAllowance(address _spender, uint256 _amount) external returns(bool) {
        address _owner = msg.sender;
        _decreaseAllowance(_owner, _spender, _amount);

        return true;
    }

    function transfer(address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _from = msg.sender;
        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount, bytes calldata _data) external returns(bool) {
        address _spender = msg.sender;
        _spendApproval(_from, _spender, _amount);
        _transfer(_from, _to, _amount, _data);

        return true;
    }

    function batchApprove(address[] calldata _spender, uint256[] calldata _amount) external returns(bool) {

    }

    function batchDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount) external returns(bool) {

    }

    function batchTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool) {

    }

    function batchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool) {

    }

    /**
    * Cross-chain functions
    */
    function crossChainApprove(address _spender, uint256 _amount, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {

    }

    function crossChainBatchApprove(address[] calldata _spender, uint256[] calldata _amount, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {

    }

    function crossChainDecreaseAllowance(address _spender, uint256 _amount, bytes32 _destinationChainID, address _destinationContract) external {

    }

    function crossChainBatchDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external {

    }

    function crossChainTransfer(address _to, uint256 _amount, bytes calldata _data, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {

    }

    function crossChainBatchTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {

    }

    function crossChainTransferFrom(address _from, address _to, uint256 _amount, bytes calldata _data, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {

    }

    function crossChainBatchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {

    }

    function _approve(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "wrong address");
        require(_spender != address(0), "wrong address");
        require(_amount > 0, "invalid amount");

        uint256 _approval = _approvals[_owner][_spender];
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;
        uint256 _balance = balanceOf(_owner);

        require(block.timestamp < _maturityDate, "matured");
        require(_amount <= _balance, "insufficient balance");
        require((_amount * _denomination) % _denomination == 0, "invalid amount");

        _approvals[_owner][_spender]  = _approval + _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _decreaseAllowance(address _owner, address _spender, uint256 _amount) internal virtual {
        require(_owner != address(0), "wrong address");
        require(_spender != address(0), "wrong address");
        require(_amount > 0, "invalid amount");

        uint256 _approval = _approvals[_owner][_spender];
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;

        require(block.timestamp < _maturityDate, "matured");
        require(_amount <= _approval, "insufficient approval");
        require((_amount * _denomination) % _denomination == 0, "invalid amount");

        _approvals[_owner][_spender]  = _approval - _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) internal virtual {
        require(_from != address(0), "wrong address");
        require(_to != address(0), "wrong address");
        require(_amount > 0, "invalid amount");

        uint256 principal = _principals[_from];
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;

        uint256 _balance = balanceOf(_from);

        require(block.timestamp < _maturityDate, "matured");
        require(_amount <= _balance, "insufficient balance");
        require((_amount * _denomination) % _denomination == 0, "invalid amount");

        uint256 principalTo = _principals[_to];

        _beforeBondTransfer(_from, _to, _amount, _data);

        unchecked {
            uint256 _principalTransferred = _amount * _denomination;

            _principals[_from] = principal - _principalTransferred;
            _principals[_to] = principalTo + _principalTransferred;
        }

        emit Transfer(_from, _to, _amount);

        _afterBondTransfer(_from, _to, _amount, _data);
    }

    function _spendApproval(address _from, address _spender, uint256 _amount) internal virtual {
        uint256 currentApproval = _approvals[_from][_spender];
        require(_amount <= currentApproval, "insufficient allowance");

        unchecked {
            _approvals[_from][_spender] = currentApproval - _amount;
        }
   }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        (bool success, ) = address(this).call(any2EvmMessage.data);
        require(success);

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        );
    }

    function _beforeBondTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) internal virtual {}

    function _afterBondTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) internal virtual {}
}