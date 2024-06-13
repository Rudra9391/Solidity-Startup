// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract EscrowService {
    struct Escrow {
        address client;
        address payable freelancer;
        uint256 amount;
        string description;
        uint256 deadline;
        bool fundsReleased;
        bool fundsRefunded;
    }

    Escrow[] public escrows;

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed client,
        address indexed freelancer,
        uint256 amount,
        string description,
        uint256 deadline
    );

    event FundsReleased(uint256 indexed escrowId);
    event FundsRefunded(uint256 indexed escrowId);

    function createEscrow(
        address payable _freelancer,
        string memory _description,
        uint256 _deadline
    ) external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(_freelancer != address(0), "Freelancer address cannot be zero");

        escrows.push(
            Escrow({
                client: msg.sender,
                freelancer: _freelancer,
                amount: msg.value,
                description: _description,
                deadline: block.timestamp + _deadline,
                fundsReleased: false,
                fundsRefunded: false
            })
        );

        emit EscrowCreated(
            escrows.length - 1,
            msg.sender,
            _freelancer,
            msg.value,
            _description,
            block.timestamp + _deadline
        );
    }

    function releaseFunds(uint256 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.client, "Only the client can release funds");
        require(!escrow.fundsReleased, "Funds already released");
        require(!escrow.fundsRefunded, "Funds already refunded");

        escrow.fundsReleased = true;
        escrow.freelancer.transfer(escrow.amount);

        emit FundsReleased(_escrowId);
    }

    function refundFunds(uint256 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.client, "Only the client can refund funds");
        require(!escrow.fundsReleased, "Funds already released");
        require(!escrow.fundsRefunded, "Funds already refunded");
        require(block.timestamp >= escrow.deadline, "Deadline has not passed");

        escrow.fundsRefunded = true;
        payable(escrow.client).transfer(escrow.amount);

        emit FundsRefunded(_escrowId);
    }

    function getEscrowDetails(uint256 _escrowId)
        external
        view
        returns (
            address client,
            address freelancer,
            uint256 amount,
            string memory description,
            uint256 deadline,
            bool fundsReleased,
            bool fundsRefunded
        )
    {
        Escrow storage escrow = escrows[_escrowId];
        return (
            escrow.client,
            escrow.freelancer,
            escrow.amount,
            escrow.description,
            escrow.deadline,
            escrow.fundsReleased,
            escrow.fundsRefunded
        );
    }

    function getOngoingEscrows() external view returns (Escrow[] memory) {
        uint256 ongoingCount = 0;

        for (uint256 i = 0; i < escrows.length; i++) {
            if (!escrows[i].fundsReleased && !escrows[i].fundsRefunded) {
                ongoingCount++;
            }
        }

        Escrow[] memory ongoingEscrows = new Escrow[](ongoingCount);
        uint256 index = 0;

        for (uint256 i = 0; i < escrows.length; i++) {
            if (!escrows[i].fundsReleased && !escrows[i].fundsRefunded) {
                ongoingEscrows[index] = escrows[i];
                index++;
            }
        }

        return ongoingEscrows;
    }

    function getCompletedAndCancelledEscrows() external view returns (Escrow[] memory) {
        uint256 historyCount = 0;

        for (uint256 i = 0; i < escrows.length; i++) {
            if (escrows[i].fundsReleased || escrows[i].fundsRefunded) {
                historyCount++;
            }
        }

        Escrow[] memory historyEscrows = new Escrow[](historyCount);
        uint256 index = 0;

        for (uint256 i = 0; i < escrows.length; i++) {
            if (escrows[i].fundsReleased || escrows[i].fundsRefunded) {
                historyEscrows[index] = escrows[i];
                index++;
            }
        }

        return historyEscrows;
    }
}
