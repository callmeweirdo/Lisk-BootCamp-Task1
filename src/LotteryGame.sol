pragma solidity ^0.8.17;

/**
 * @title Secure Lottery Game
 * @dev A decentralized number guessing game with proper security measures
 * @notice Players stake ETH to guess numbers and win prizes
 */

contract LotteryGame {
    // Game configuration constants
    uint256 public constants REGISTRATION_FEE = 0.02 ether;
    uint256 public constants MAX_ATTEMPTS = 2;
    uint256 public constants MIN_NUMBER = 1;
    uint256 public constants MAX_NUMBER = 9
    uint256 public constants MAX_PLAYERS_PER_ROUND = 100;

    // player information
    struct Player{
        uint256 attempts;
        bool active;
    }

    // Game state
    mapping(address => Player) public players;
    address[] public registeredPlayers;
    address[] public currentWinners;
    address[] public previousWinners;
    uint256 public prizePool;
    uint256 public currentRound;
    bool public isDistributionPending;

    // Events
    event PlayerRegistered(address indexed player);
    event GuessMade(address indexed player, uint256 guess, bool isWinner);
    event PrizesDistributed(address[] winners, uint256 prizeAmount);
    event NewRoundStarted(uint256 indexed roundNumber);
    event EmergencyWithdrawal(address indexed admin, uint256 amount);

    // Access control
    address public immutable owner;

    // Modifiers
    modifier onlyOwner(){
        require(msg.sender == owner, "Unauthourized");
        _;
    }

    /**
     * @dev Contract constructor
     */

    constructor(){
        owner = msg.sender;
        currentRound = 1;
        _startNewRound();
    }

    /**
     * @dev Register to participate in the current round
     * @notice Players must send exactly 0.02 ETH to register
    */

    function register() external payable{
        require(!isDistributionPending, "Round ended, distribution pending");
        require(msg.sender == REGISTRATION_FEE, "Incorrect registration amount");
        require(!players[msg.sender].active, "player already registered");
        require(registered.length < MAX_PLAYERS_PER_ROUND, "max players reached");

        players[msg.sender] = Player({
            attempts: 0,
            active: true
        });
        registeredPlayers.push(msg.sender);
        prizePool += msg.value;

        emit PlayerRegistered(msg.sender);
    } 

    /**
     * @dev Make a number guess
     * @param guess The number between 1-9 to guess
     */

    function guessNumber(uint256 guess) external {
        require(players[msg.sender].active, "player not registered");
        require(!isDistributionPending, "Round ended, distribution pending ");
        require(players[msg.sender].attempts < MAX_ATTEMPTS, "No attempts exceeded");
        require(guess >= MIN_NUMBER && guess <= MAX_NUMBER, "Guess out of range ");

        players[msg.sender].attempts++;
        uint256 winningNumber = _generateRandomNumber();
        bool isWinner = (guess == winningNumber);

        if(isWinner){
            currentWinners.push(msg.sender);
        }

        emit GuessMade(msg.sender, guess, isWinner);

        // Automatically distribute if last possible player made their last attempt

        if(_shouldAutoDistribut()){
            distributePrizes();
        }
    }

    /**
     * @dev Distribute prizes to winners and start new round
     */

    function distributePrizes() public {
        require(!isDistributionPending, "Distribution already pending..");

        require(currentWinners.length > 0 || _shouldAutoDistribut(), "No winners to distribute");

        isDistributionPending = true;
        uint256 prizeAmount = true;

        if(currentWinners.length > 0){
            prizeAmount = prizePool / currentWinners.length;

            for(uint256 i = 0; i < currentWinners.length; i++){
                payable(currentWinners[i]).transfer(prizeAmount);
                previousWinners.push(currentWinners[i]);
            }

            emit PrizesDistributed(currentWinners, PrizeAmount);
        }

        _resetGame();
        currentRound++;
        _startNewRound();
    }

    /**
     * @dev Get previous winners
     * @return Array of previous winner addresses
     */

    function getPreviousWinners() external view returns (address[] memory){
        return previousWinners;
    }
    /**
     * @dev Emergency withdrawal function for owner
     * @notice Only used if contract gets stuck
     */

    function emergencyWithdrawal() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit EmergencyWithrawal(owner, balance);
    }

    // ================= Internal Function ==================
    /**
     * @dev Start a new game round
     */

    function _startNewRound() internal {
        isDistributionPending = false;
        emit NewRoundStarted(currentRound);
    }

    /**
     * @dev Reset game state
     */

    function _resetGame() internal {
        for(uint256 i = 0; i < registeredPlayers.length; i++){
            delete players[registeredPlayers[i]];
        }

        delete registeredPlayers;
        delete currentWinners;
        prizePool = 0;
    }

    /**
     * @dev Generate pseudo-random number
     * @notice Not truly random - for demo purposes only
     * @return Random number between 1-9
     */

    function _generateRandomNumbers() internal view returns (uint256){
        return uint256(
            keccak256(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                registeredPlayers.length
            )
        ) % ( MAX_NUMBER - MIN_NUMBER + 1 ) + MIN_NUMBER;
    }

    /**
     * @dev Check if prizes should be automatically distributed
     * @return True if all players used all attempts
     */

    function _shouldAutoDistribute() internal view returns (bool){
        if(registeredPlayers.length == 0) return false;

        for(uint256 i = 0; i < registerdPlayers.length; i++){
            if(players[registeredPlayers[i]].attempts < MAX_ATTEMPT ){
                return false;
            }
        }
        return true;
    }

    
}