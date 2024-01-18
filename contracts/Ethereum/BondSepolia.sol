// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC7092.sol";
import "../BondStorage.sol";

contract BondSepolia is IERC7092, IERC7092CrossChain, BondStorage, CCIPReceiver {
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

    function totalSupply() external view returns(uint256) {
        uint256 _issueVolume = bonds.issueVolume;
        uint256 _denomination = bonds.denomination;

        return _issueVolume / _denomination;
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
        address _owner = msg.sender;
        _batchApprove(_owner, _spender, _amount);

        return true;
    }

    function batchDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount) external returns(bool) {
        address _owner = msg.sender;
        _batchDecreaseAllowance(_owner, _spender, _amount);

        return true;
    }

    function batchTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool) {
        address[] memory _from;
        for(uint256 i; i < _to.length; i++) {
            _from[i] = msg.sender;
        }

        _batchTransfer(_from, _to, _amount, _data);

        return true;
    }

    function batchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data) external returns(bool) {
        address _spender = msg.sender;
        _batchSpendApproval(_from, _spender, _amount);
        _batchTransfer(_from, _to, _amount, _data);

        return true;
    }

    /**
    * Cross-chain functions
    */
    function crossChainApprove(address _spender, uint256 _amount, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {
        address _owner = msg.sender;
        _crossChainApproval(_owner, _spender, _amount, _destinationChainID, _destinationContract, "crossApprove(address,address,uint256)");

        return true;
    }

    function crossChainBatchApprove(address[] calldata _spender, uint256[] calldata _amount, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {
        address _owner = msg.sender;
        _crossChainBatchApproval(_owner, _spender, _amount, _destinationChainID, _destinationContract, "crossApprove(address,address,uint256)");

        return true;
    }

    function crossChainDecreaseAllowance(address _spender, uint256 _amount, bytes32 _destinationChainID, address _destinationContract) external {
        address _owner = msg.sender;
        _crossChainApproval(_owner, _spender, _amount, _destinationChainID, _destinationContract, "crossDecreaseAllowance(address,address,uint256)");
    }

    function crossChainBatchDecreaseAllowance(address[] calldata _spender, uint256[] calldata _amount, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external {
        address _owner = msg.sender;
        _crossChainBatchApproval(_owner, _spender, _amount, _destinationChainID, _destinationContract, "crossDecreaseAllowance(address,address,uint256)");
    }

    function crossChainTransfer(address _to, uint256 _amount, bytes calldata _data, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {
        address _from = msg.sender;
        _crossChainTransfer(_from, _to, _amount, _data, _destinationChainID, _destinationContract, "crossTransfer(address,address,uint256,bytes)");

        return true;
    }

    function crossChainBatchTransfer(address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {

    }

    function crossChainTransferFrom(address _from, address _to, uint256 _amount, bytes calldata _data, bytes32 _destinationChainID, address _destinationContract) external returns(bool) {

    }

    function crossChainBatchTransferFrom(address[] calldata _from, address[] calldata _to, uint256[] calldata _amount, bytes[] calldata _data, bytes32[] calldata _destinationChainID, address[] calldata _destinationContract) external returns(bool) {

    }

    /**
    * Functions to execute on the client side for cross-chain transactions
    * NB: These functions MUST check that the msg.sender equals to bridge contract  
    */
    function crossApprove(address _owner, address _spender, uint256 _amount) public {
        _approve(_owner, _spender, _amount);
    }

    function crossDecreaseAllowance(address _owner, address _spender, uint256 _amount) public {
        _decreaseAllowance(_owner, _spender, _amount);
    }

    function crossTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) public {
        _transfer(_from, _to, _amount, _data);
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

   function _batchApprove(address _owner, address[] calldata _spender, uint256[] calldata _amount) internal virtual {
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;
        uint256 _balance = balanceOf(_owner);

        require(_owner != address(0), "wrong address");
        require(block.timestamp < _maturityDate, "matured");

        uint256 totalAmount;
        for(uint256 i; i < _spender.length; i++) {
            totalAmount = totalAmount + _amount[i];

            require(_spender[i] != address(0), "wrong address");
            require(_amount[i] > 0, "invalid amount");
            require(totalAmount <= _balance, "insufficient balance");
            require((totalAmount * _denomination) % _denomination == 0, "invalid amount");

            uint256 _approval = _approvals[_owner][_spender[i]];

            _approvals[_owner][_spender[i]]  = _approval + _amount[i];
        }

        emit ApprovalBatch(_owner, _spender, _amount);
    }

    function _batchDecreaseAllowance(address _owner, address[] calldata _spender, uint256[] calldata _amount) internal virtual {
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;

        require(_owner != address(0), "wrong address");
        require(block.timestamp < _maturityDate, "matured");

        for(uint256 i; i < _spender.length; i++) {
            uint256 _approval = _approvals[_owner][_spender[i]];

            require(_amount[i] <= _approval, "insufficient approval");
            require(_amount[i] > 0, "invalid amount");
            require((_amount[i] * _denomination) % _denomination == 0, "invalid amount");

            _approvals[_owner][_spender[i]]  = _approval - _amount[i];
        }

        emit ApprovalBatch(_owner, _spender, _amount);
    }

    function _batchTransfer(
        address[] memory _from,
        address[] memory _to,
        uint256[] calldata _amount,
        bytes[] calldata _data
    ) internal virtual {
        uint256 _denomination = bonds.denomination;
        uint256 _maturityDate = bonds.maturityDate;

        require(block.timestamp < _maturityDate, "matured");

        for(uint256 i; i < _from.length; i++) {
            uint256 principal = _principals[_from[i]];
            uint256 _balance = balanceOf(_from[i]);

            require(_from[i] != address(0), "wrong address");
            require(_to[i] != address(0), "wrong address");
            require(_amount[i] > 0, "invalid amount");
            require(_amount[i] <= _balance, "insufficient balance");
            require((_amount[i] * _denomination) % _denomination == 0, "invalid amount");

            uint256 principalTo = _principals[_to[i]];

            _batchBeforeBondTransfer(_from, _to, _amount, _data);

            unchecked {
                uint256 _principalTransferred = _amount[i] * _denomination;

                _principals[_from[i]] = principal - _principalTransferred;
                _principals[_to[i]] = principalTo + _principalTransferred;
            }

            emit TransferBatch(_from, _to, _amount);

            _batchAfterBondTransfer(_from, _to, _amount, _data);
        }
    }

    function _batchSpendApproval(address[] calldata _from, address _spender, uint256[] calldata _amount) internal virtual {
        for(uint256 i; i < _from.length; i++) {
            uint256 currentApproval = _approvals[_from[i]][_spender];
            require(_amount[i] <= currentApproval, "insufficient allowance");

            unchecked {
                _approvals[_from[i]][_spender] = currentApproval - _amount[i];
            }
        }
    }

    function _crossChainApproval(
        address _owner,
        address _spender,
        uint256 _amount,
        bytes32 _destinationChainID,
        address _destinationContract,
        string memory _functionSignature
    ) internal virtual returns(bytes32 messageId) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_destinationContract),
            data: abi.encodeWithSignature(_functionSignature, _owner, _spender, _amount),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            feeToken: address(linkToken)
        });

        uint64 destinationChainSelector = uint64(uint256(_destinationChainID));
        uint256 fees = router.getFee(destinationChainSelector, message);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

        linkToken.approve(address(router), fees);

        messageId = router.ccipSend(destinationChainSelector, message);

        emit MessageSent(messageId, destinationChainSelector, _destinationContract);
    }

    function _crossChainTransfer(
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes32 _destinationChainID,
        address _destinationContract,
        string memory _functionSignature
    ) internal virtual returns(bytes32 messageId) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(_destinationContract),
            data: abi.encodeWithSignature(_functionSignature, _from, _to, _amount, _data),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 200_000})
            ),
            feeToken: address(linkToken)
        });

        uint64 destinationChainSelector = uint64(uint256(_destinationChainID));
        uint256 fees = router.getFee(destinationChainSelector, message);

        if (fees > linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

        linkToken.approve(address(router), fees);

        messageId = router.ccipSend(destinationChainSelector, message);

        emit MessageSent(messageId, destinationChainSelector, _destinationContract);
    }

    function _crossChainBatchApproval(
        address _owner,
        address[] calldata _spender,
        uint256[] calldata _amount,
        bytes32[] calldata _destinationChainID,
        address[] calldata _destinationContract,
        string memory _functionSignature
    ) internal virtual returns(bytes32[] memory messageId) {
        uint64[] memory chainSelectors;
        for(uint256 i; i < _spender.length; i++) {
            Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
                receiver: abi.encode(_destinationContract[i]),
                data: abi.encodeWithSignature(_functionSignature, _owner, _spender[i], _amount[i]),
                tokenAmounts: new Client.EVMTokenAmount[](0),
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({gasLimit: 200_000})
                ),
                feeToken: address(linkToken)
            });

            uint64 destinationChainSelector = uint64(uint256(_destinationChainID[i]));
            uint256 fees = router.getFee(destinationChainSelector, message);

            chainSelectors[i] = destinationChainSelector;

            if (fees > linkToken.balanceOf(address(this)))
                revert NotEnoughBalance(linkToken.balanceOf(address(this)), fees);

            linkToken.approve(address(router), fees);

            bytes32 id = router.ccipSend(destinationChainSelector, message);
            messageId[i] = id;
        }

        emit MessageSent(messageId, chainSelectors, _destinationContract);
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
    function _batchBeforeBondTransfer(address[] memory _from, address[] memory _to, uint256[] calldata _amount, bytes[] calldata _data) internal virtual {}
    function _batchAfterBondTransfer(address[] memory _from, address[] memory _to, uint256[] calldata _amount, bytes[] calldata _data) internal virtual {}
}