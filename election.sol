pragma solidity ^0.5.0;

contract Election 
{
    struct Candidate 
    {
        uint id;
        address addr;
        string name;
        string promises;
        uint votes;
    }
    
    struct Voter 
    {
        uint id;
        address addr;
        string name;
    }
    
    uint public candidateCount = 0;
    uint public voterCount = 0;
    uint winnerIndex = 99999;
    address winner;
    uint noWins = 0;
    uint[] winnersIndex; 
    address owner;
    mapping(uint => Candidate) candidatesList;
    mapping (address => bool) candidateAlreadyRegistered;
    mapping (address => bool) candidateAlreadyVoted;
    mapping(uint => Voter) votersList;
    mapping (address => bool) voterAlreadyRegistered;
    mapping (address => bool) voterAlreadyVoted;
    
    event WinnerIsDeclared(address indexed _winner, uint indexed _winnerIndex);
    
    function viewWinner() public view returns (string memory name, string memory promises, uint votes)
    {
        require(winnerIndex != 99999, "Winner not declared yet");
        if(winnersIndex.length == 1)
        {
            Candidate memory c = candidatesList[winnerIndex];
            return (c.name, c.promises, c.votes);
        }
        else
        {   
            Candidate memory c = candidatesList[winnerIndex];
            return ("multiple winners","None",c.votes);
        }
    }
    
    constructor() public 
    {
        owner = msg.sender;
    }
    
    modifier onlyCreator() 
    {
        require(msg.sender == owner, "You need to be creator of this smart contract!");
        _;
    }
    
    function checkCandidateadd() private view returns (uint index)
    {
        for(uint i=0; i< candidateCount;i++)
        {
            if(candidatesList[i].addr == msg.sender)
            { 
                return i;
            }
        }
        return 0;
    }
    
    function registerAsCandidate(string memory _name, string memory _promises) payable public 
    {
        require(msg.sender != owner, "Creator cannot register as Candidate!");
        require(candidateAlreadyRegistered[msg.sender] == false, "You've already registered!");
        require(msg.value == 1 ether, "You need to pay 1 ether to register for elections!");
        require(bytes(_name).length >= 1, "Name should be at least one character long");
        require(bytes(_promises).length >= 1, "Promise should not be an empty promise!");
        
        candidateAlreadyRegistered[msg.sender] = true;
        candidatesList[candidateCount] = Candidate(candidateCount, msg.sender, _name, _promises, 0);
        candidateCount++;
        voterCount ++;
    }
    
    function registerAsVoter(string memory _name) payable public 
    {
        require(voterAlreadyRegistered[msg.sender] == false, "You've already registered!");
        require(bytes(_name).length >= 1, "Name should be at least one character long");
        
        voterAlreadyRegistered[msg.sender] = true;
        votersList[voterCount] = Voter(voterCount, msg.sender, _name);
        voterCount ++;
    }
    
    function viewCandidate(uint index) public view returns (string memory name, string memory promises) 
    {
        
        Candidate memory c = candidatesList[index];
        return (c.name, c.promises);
    }
    
    function checkCandidateVotes(uint index) public view onlyCreator returns (string memory name, string memory promises, uint votes) 
    {
        
        Candidate memory c = candidatesList[index];
        return (c.name, c.promises, c.votes);
    }
    
    function voteForCandidate(uint index) public 
    {
        require(index >= 0 && index < candidateCount, "Invalid index for Candidate");
        require(msg.sender != candidatesList[index].addr, "You cannot vote for yourself!");
        require(voterAlreadyVoted[msg.sender] == false || candidateAlreadyVoted[msg.sender] == false , "You can't vote more than once!");
        
        uint candAdd = checkCandidateadd();
        if(candAdd != 0)
        {
            candidateAlreadyVoted[msg.sender] = true;
        }
        else
        {
            voterAlreadyVoted[msg.sender] = true;
        }
        Candidate storage c = candidatesList[index];
        c.votes++;
    }
    
    function declareWinner() public onlyCreator
    {
        require(candidateCount > 0, "Need to have candidates to declare winner!");
        uint maxVotesSeenTillNow = 0;
        uint winIndex = candidateCount+1;
        
        for(uint i=0; i< candidateCount;i++)
        {
            if(candidatesList[i].votes > maxVotesSeenTillNow)
            { 
                maxVotesSeenTillNow = candidatesList[i].votes;
                winIndex = i;
                winnersIndex.push(winIndex);
            }
        }
        
        for(uint i=0; i< candidateCount;i++)
        {
            if(candidatesList[i].votes == maxVotesSeenTillNow && (winIndex != i))
            { 
                winnersIndex.push(i);
            }
        }
        
        winner = candidatesList[winIndex].addr;
        winnerIndex = winIndex;
        emit WinnerIsDeclared(winner, winIndex);
    }
}
