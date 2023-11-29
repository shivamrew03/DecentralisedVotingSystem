// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    struct Candidate {
        string name;
        uint age;
        bool isAlive;
        uint netWorth; // Total net worth of the candidate
        bool hasBadCriminalRecord;
        uint numVotes;
    }

    struct Voter {
        string name;
        uint age;
        bool isAlive;
        bool isAuthorized;
        bool hasVoted;
        bool verifiedByZKP; 
        uint vote;
        uint netWorth;
        bool hasBadCriminalRecord;
        bool runningForElect;
    }
    bool isFinished = false;
    uint256 private t1;
    uint256 private t2;

    address private owner;
    string public electionName;
    Candidate public winner;

    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;
    mapping(uint => bool) private usedZKPs; // Mapping to track used ZKPs

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor(string memory _name) {
        owner = msg.sender;
        electionName = _name;
        t1 = block.timestamp;
        winner.name = "Election is under process!";
    }

    function runForElection() public {
        require(!isFinished,"Election has ended");
        require(voters[msg.sender].age >= 25, "Candidate must be at least 25 years old.");
        require(voters[msg.sender].isAlive, "Deceased individuals are not allowed to become candidates.");
        require(!voters[msg.sender].hasBadCriminalRecord, "Candidates with bad criminal records are not allowed.");
        require(voters[msg.sender].isAuthorized, "You are not allowed to run for the election.");
        candidates.push(Candidate(voters[msg.sender].name, voters[msg.sender].age, voters[msg.sender].isAlive, voters[msg.sender].netWorth, voters[msg.sender].hasBadCriminalRecord, 0));
    }

    function numOfCandidates() public view returns(uint) {
        return candidates.length;
    }
    
    function validateZKP(uint zkp) pure private returns (bool) {
        if (zkp > 0) return true;
        return false;
    }

    function authorizeUser(string memory _name, uint _age, bool _isAlive, bool _hasBadCriminalRecord, uint netWorth, uint zkp) public {
        require(!isFinished,"Election has ended");
        require(_age >= 18, "Voter must be at least 18 years old.");
        require(_age < 150, "Voter must be alive.");
        require(!_hasBadCriminalRecord, "Voters with bad criminal records are not allowed.");
        require(!voters[msg.sender].isAuthorized, "You have already been registered as a voter.");
        require(!usedZKPs[zkp], "This ZKP has already been used."); // Check if the ZKP has been used before
        require(validateZKP(zkp), "You are not an authorised Indian citizen.");
        require(!voters[msg.sender].runningForElect,"You have already been registered for election");
        address voterAddress = msg.sender;
        voters[voterAddress] = Voter(_name, _age, _isAlive, true, false, true, 9999, netWorth, _hasBadCriminalRecord,true);
        usedZKPs[zkp] = true; // Mark the ZKP as used
    }

    function vote(uint _voteIndex) public {
        require(!isFinished,"Election has ended");
        require(!voters[msg.sender].hasVoted, "You have already voted.");
        require(voters[msg.sender].isAuthorized, "You are not authorized to vote.");
        require(voters[msg.sender].age >= 18, "You must be at least 18 years old to vote.");
        require(voters[msg.sender].isAlive, "Deceased individuals are not allowed to vote.");
        require(voters[msg.sender].verifiedByZKP, "Voter data must be verified with Aadhar database.");

        voters[msg.sender].vote = _voteIndex;
        voters[msg.sender].hasVoted = true;

        candidates[_voteIndex].numVotes += 1;
        totalVotes += 1;
    }

    function winningCandidate() private view returns (uint _winningCandidate) {
        uint winningVoteCount = 0;
        uint winningCandidateIndex = 9999;

        for (uint i = 0; i < numOfCandidates(); i++) {
            if (candidates[i].numVotes > winningVoteCount) {
                winningVoteCount = candidates[i].numVotes;
                winningCandidateIndex = i;
            } else if (candidates[i].numVotes == winningVoteCount && i != winningCandidateIndex) {
                winningCandidateIndex = 9999;
            }
        }
        _winningCandidate = winningCandidateIndex;
        // Candidate[_winningCandidate].name;
    }
    
    uint256 public TotalTimeElapsed;

    function endElection() public onlyOwner {
        require(!isFinished,"Election has already ended");
        uint winningCandidateIndex = winningCandidate();
        t2 = block.timestamp;
        TotalTimeElapsed = t2 - t1;
        if (winningCandidateIndex == 9999) {
            winner.name = "It's a tie!";
        } else {
            winner = candidates[winningCandidateIndex];
        }
        isFinished = true;
    }
}
