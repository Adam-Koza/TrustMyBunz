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
        uint arbitrator_fee;
        uint expiryDate;
        bool buyerApprove;
        bool arbitrator_percent;
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
        TransactionInfo[transactionID].arbitrator_fee = ArbitratorInfo[_arbitrator].fee;
        TransactionInfo[transactionID].arbitrator_percent = ArbitratorInfo[_arbitrator].percent;
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
    
    // Arbitrator chooses buyer to win.
    function buyerWins (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved &&
            TransactionInfo[_transactionID].conflict &&
            (msg.sender == TransactionInfo[_transactionID].arbitrator) && 
            (block.number < TransactionInfo[_transactionID].expiryDate));
            
        if (!TransactionInfo[_transactionID].arbitrator_percent) {
            // Flat fee.
            TransactionInfo[_transactionID].totalValue -= TransactionInfo[_transactionID].arbitrator_fee;
            TransactionInfo[_transactionID].arbitrator.transfer(TransactionInfo[_transactionID].arbitrator_fee);
        } else {
            // Percentage.
            uint arbitration_fee = (TransactionInfo[_transactionID].arbitrator_fee / 100) * TransactionInfo[_transactionID].totalValue;
            TransactionInfo[_transactionID].totalValue -= arbitration_fee;
            TransactionInfo[_transactionID].arbitrator.transfer(arbitration_fee);
        }
        
        TransactionInfo[_transactionID].buyer.transfer(TransactionInfo[_transactionID].totalValue);
        TransactionInfo[transactionID].resolved = true;
    }
    
    // Arbitrator chooses seller to win.
    function sellerWins (uint _transactionID) public {
        require(!TransactionInfo[_transactionID].resolved &&
            TransactionInfo[_transactionID].conflict &&
            (msg.sender == TransactionInfo[_transactionID].arbitrator) && 
            (block.number < TransactionInfo[_transactionID].expiryDate));
            
        if (!TransactionInfo[_transactionID].arbitrator_percent) {
            // Flat fee.
            TransactionInfo[_transactionID].totalValue -= TransactionInfo[_transactionID].arbitrator_fee;
            TransactionInfo[_transactionID].arbitrator.transfer(TransactionInfo[_transactionID].arbitrator_fee);
        } else {
            // Percentage.
            uint arbitration_fee = (TransactionInfo[_transactionID].arbitrator_fee / 100) * TransactionInfo[_transactionID].totalValue;
            TransactionInfo[_transactionID].totalValue -= arbitration_fee;
            TransactionInfo[_transactionID].arbitrator.transfer(arbitration_fee);
        }
        
        TransactionInfo[_transactionID].seller.transfer(TransactionInfo[_transactionID].totalValue);
        TransactionInfo[transactionID].resolved = true;
    }
    
    // Arbitrator sets fee. Either flat fee or percentage of transaction.
    function setFee (uint _fee, bool _percentage) public {
        ArbitratorInfo[msg.sender].fee = _fee;
        ArbitratorInfo[msg.sender].percent = _percentage;
    }   
}
