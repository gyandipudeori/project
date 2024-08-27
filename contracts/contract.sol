// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AlumniDonationDAO {
    
    struct Proposal {
        string description;
        uint256 amount;
        address payable recipient;
        uint256 voteCount;
        bool executed; 
    }

    address public owner;
    mapping(address => bool) public alumni;
    mapping(uint256 => mapping(address => bool)) public votes;
    Proposal[] public proposals;

    modifier onlyAlumni() {
        require(alumni[msg.sender], "Not an approved alumnus.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addAlumnus(address _alumnus) external onlyOwner {
        alumni[_alumnus] = true;
    }

    function removeAlumnus(address _alumnus) external onlyOwner {
        alumni[_alumnus] = false;
    }

    function donate() external payable onlyAlumni {
        require(msg.value > 0, "Donation must be greater than 0.");
    }

    function createProposal(string memory _description, uint256 _amount, address payable _recipient) external onlyAlumni {
        require(_amount <= address(this).balance, "Requested amount exceeds contract balance.");
        proposals.push(Proposal({
            description: _description,
            amount: _amount,
            recipient: _recipient,
            voteCount: 0,
            executed: false
        }));
    }

    function voteOnProposal(uint256 _proposalIndex) external onlyAlumni {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        require(!votes[_proposalIndex][msg.sender], "Already voted on this proposal.");
        require(!proposals[_proposalIndex].executed, "Proposal already executed.");

        proposals[_proposalIndex].voteCount += 1;
        votes[_proposalIndex][msg.sender] = true;
    }

    function executeProposal(uint256 _proposalIndex) external onlyAlumni {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        Proposal storage proposal = proposals[_proposalIndex];

        require(!proposal.executed, "Proposal already executed.");
        require(proposal.voteCount > (alumniCount() / 2), "Not enough votes to execute.");

        proposal.executed = true;
        proposal.recipient.transfer(proposal.amount);
    }

    function alumniCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (alumni[address(uint160(i))]) {
                count++;
            }
        }
        return count;
    }

    function getProposal(uint256 _proposalIndex) public view returns (string memory, uint256, address, uint256, bool) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");
        Proposal storage proposal = proposals[_proposalIndex];
        return (proposal.description, proposal.amount, proposal.recipient, proposal.voteCount, proposal.executed);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
