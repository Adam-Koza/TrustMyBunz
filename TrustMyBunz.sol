pragma solidity 0.4.25;

contract TrustMyBunz {
    
    uint public transactionID;
    
    
    struct Transaction {
        address sender;
        address arbitrator;
        address recipient;
        uint totalValue;
        uint trancheCount;
        uint trancheValue;
        bool conflict;
        bool resolved;
    }
    
    
    
    struct Arbitrator {
        uint fee;
        bool percent;
    }
    
    
    
    mapping(uint => Transaction) TransactionInfo;
    mapping(address => Arbitrator) ArbitratorInfo;
    
    constructor() public {
        transactionID = 0;
    }
    
    function newTransaction (address _arbitrator, address _recipient, uint _trancheCount) payable public {
        transactionID += 1;
        TransactionInfo[transactionID].sender = msg.sender;
        TransactionInfo[transactionID].arbitrator = _arbitrator;
        TransactionInfo[transactionID].recipient = _recipient;
        TransactionInfo[transactionID].totalValue = msg.value;
        TransactionInfo[transactionID].trancheCount = _trancheCount;
        TransactionInfo[transactionID].trancheValue = msg.value / _trancheCount;
    }
    
    function senderSatisfied (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved && (TransactionInfo[_transactionID].recipient != 0x0));
        // Add dispute window even if satisfied.
        TransactionInfo[_transactionID].recipient.transfer(TransactionInfo[_transactionID].trancheValue);
        if ((TransactionInfo[_transactionID].totalValue - TransactionInfo[_transactionID].trancheValue) == 0) {
            TransactionInfo[transactionID].resolved = true;
        }
        
    }
        
        
        
        
    
    
    
    
}
