pragma solidity 0.4.25;

contract TrustMyBunz {
    
    uint public transactionID;
    
    
    struct Transaction {
        address buyer;
        address arbitrator;
        address seller;
        uint totalValue;
        uint trancheCount;
        uint trancheValue;
        uint expiryDate;
        bool buyerApprove;
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
        if (_trancheCount <= 0) {
            _trancheCount = 1;
        }
        transactionID += 1;
        TransactionInfo[transactionID].buyer = msg.sender;
        TransactionInfo[transactionID].arbitrator = _arbitrator;
        TransactionInfo[transactionID].seller = _recipient;
        TransactionInfo[transactionID].totalValue = msg.value;
        TransactionInfo[transactionID].trancheCount = _trancheCount;
        TransactionInfo[transactionID].trancheValue = msg.value / _trancheCount;
        // Transaction expires in 60 days. 
        TransactionInfo[transactionID].expiryDate = block.number + 2419200;
    }
    
    function buyerSatisfied (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved && (TransactionInfo[_transactionID].seller != 0x0) && (msg.sender == TransactionInfo[_transactionID].buyer));
        // Add 24hr dispute window even if satisfied.
        TransactionInfo[_transactionID].expiryDate = block.number + 5760;
        TransactionInfo[_transactionID].buyerApprove = true;
    }
    
    function sellerCollect (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved && 
            !TransactionInfo[_transactionID].conflict && 
            (msg.sender == TransactionInfo[_transactionID].seller) && 
            (block.number > TransactionInfo[_transactionID].expiryDate) &&
            TransactionInfo[_transactionID].buyerApprove);
        
        // Send payment to seller.
        TransactionInfo[_transactionID].seller.transfer(TransactionInfo[_transactionID].trancheValue);
        if ((TransactionInfo[_transactionID].totalValue - TransactionInfo[_transactionID].trancheValue) == 0) {
            TransactionInfo[transactionID].resolved = true;
        } else {
            TransactionInfo[_transactionID].totalValue -= TransactionInfo[_transactionID].trancheValue;
        }
    }
    
    function buyerDispute (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved && 
            (msg.sender == TransactionInfo[_transactionID].buyer) && 
            (block.number > TransactionInfo[_transactionID].expiryDate));
            
        // Conflict expires in 60 days. 
        TransactionInfo[transactionID].expiryDate = block.number + 2419200;
        TransactionInfo[transactionID].conflict = true;
    }
    
    // Transaction conflict expires.
    function buyerCollect (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved && 
            (msg.sender == TransactionInfo[_transactionID].buyer) &&
            TransactionInfo[_transactionID].conflict &&
            (block.number > TransactionInfo[_transactionID].expiryDate));
            
        // Send payment to buyer.
        TransactionInfo[_transactionID].buyer.transfer(TransactionInfo[_transactionID].totalValue);
        TransactionInfo[transactionID].resolved = true;
    }
    
    
        
    
        
        
        
        
    
    
    
    
}
