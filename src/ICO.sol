//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SpaceCoin} from "./SpaceCoin.sol";

contract ICO {
    error ICO__NotOwner();
    error ICO__Unsuccessful_Advancing();

    enum Phase {
        SEED,
        GENERAL,
        OPEN
    }

    Phase public currentPhase;
    mapping(address => uint256) public userToContributedAmount;
    address[] public s_allowList;

    address public immutable i_owner;
    SpaceCoin spaceCoin;

    uint256 public constant SEED_INDIVIDUAL_LIMIT = 1500 ether;
    uint256 public constant SEED_TOTAL_LIMIT = 15000 ether;
    uint256 public constant GENERAL_INDIVIDUAL_LIMIT = 1000 ether;
    uint256 public constant GENERAL_OR_OPEN_TOTAL_LIMIT = 30000 ether;
    uint256 public constant REEDEM_RATIO = 5;

    bool public isContributingPaused;
    bool public isRedeemingPaused;

    uint256 public totalContributions;

    event PhaseChanged(uint256 indexed newPhase);
    event Contribution(address indexed contributor, uint256 amount);
    event Redeming(address indexed contributor, uint256 amount);

    constructor(address[] memory _addresses, address owner, address spc) {
        spaceCoin = SpaceCoin(spc);
        i_owner = owner;
        totalContributions = 0;
        isContributingPaused = false;
        isRedeemingPaused = false;
        currentPhase = Phase.SEED;
        for (uint256 i = 0; i < _addresses.length; ++i) {
            s_allowList.push(_addresses[i]);
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert ICO__NotOwner();
        }
        _;
    }
    /**
     * @dev requires players and total supply to be within phase limits
     */

    modifier withinPhaseLimits(uint256 amount) {
        if (currentPhase == Phase.SEED) {
            require(
                userToContributedAmount[msg.sender] + amount <= SEED_INDIVIDUAL_LIMIT,
                "Exceeds individual SEED phase limit"
            );
            require(totalContributions + amount <= SEED_TOTAL_LIMIT, "Exceeds SEED phase limit");
        } else if (currentPhase == Phase.GENERAL) {
            require(
                userToContributedAmount[msg.sender] + amount <= GENERAL_INDIVIDUAL_LIMIT,
                "Exceeds individual GENERAL phase limit"
            );
            require(totalContributions + amount <= GENERAL_OR_OPEN_TOTAL_LIMIT, "Exceeds GENERAL phase limit");
        } else {
            require(totalContributions + amount <= GENERAL_OR_OPEN_TOTAL_LIMIT, "Exceeds OPEN phase limit");
        }
        _;
    }

    modifier whenContributingNotPaused() {
        require(!isContributingPaused, "Contributing is paused");
        _;
    }

    modifier whenRedeemingNotPaused() {
        require(!isRedeemingPaused, "Redeeming is paused");
        _;
    }

    function toggleContributePause() external onlyOwner {
        isContributingPaused = !isContributingPaused;
    }

    function toggleRedeemPause() external onlyOwner {
        isRedeemingPaused = !isRedeemingPaused;
    }

    /**
     * @dev allows users to contribute eth
     * @dev in open phase only allowlisted users can contribute
     */
    function contribute() external payable withinPhaseLimits(msg.value) whenContributingNotPaused {
        uint256 value = msg.value;
        require(value > 0, "Contribution amount must be greater than 0");
        if (currentPhase == Phase.SEED) {
            bool ind = isInAllowList(msg.sender);
            require(ind, "Only allowlisted addresses can contribute in SEED phase");
        }
        userToContributedAmount[msg.sender] += value;
        totalContributions += value;
        emit Contribution(msg.sender, value);
    }

    /**
     * @dev allows users to redeem SPC in exchange for eth with 1:5 ratio
     */
    function redeem() external whenRedeemingNotPaused {
        require(currentPhase == Phase.OPEN, "Reediming is available only in the OPEN phase");
        uint256 contributedEth = userToContributedAmount[msg.sender];
        require(contributedEth > 0, "No contribution to redeem");
        uint256 spcAmount = contributedEth * REEDEM_RATIO; // q? da li bi ovdje trebalo dodat aprove() funkciju,za isnos koji se salje, a ne da se mora pozvat u test prije toga
        userToContributedAmount[msg.sender] = 0;
        // spaceCoin.approve(address(this), spcAmount);  // ovako da se to odradi?
        //ili ovdje prosto koristiit transfer funkciju umjesto transferFrom
        bool success = spaceCoin.transferFrom(address(this), msg.sender, spcAmount);
        if (success) {
            emit Redeming(msg.sender, spcAmount);
        }
    }

    /**
     * @dev this function enables owner to change the phase
     * @dev it should prevent owner from calling it accidentaly twice
     * @param phaseNow represents the current phase
     */
    function advancePhase(uint256 phaseNow) external onlyOwner {
        require(currentPhase != Phase.OPEN, "ICO already in OPEN phase");
        if (phaseNow == 0 && currentPhase == Phase.SEED) {
            currentPhase = Phase.GENERAL;
            emit PhaseChanged(uint256(currentPhase));
        } else if (phaseNow == 1 && currentPhase == Phase.GENERAL) {
            currentPhase = Phase.OPEN;
            emit PhaseChanged(uint256(currentPhase));
        } else {
            revert ICO__Unsuccessful_Advancing();
        }
    }
    /**
     * @param contributorAddress address of the user
     * @dev checks if the user is in allowList and returns boolean
     */

    function isInAllowList(address contributorAddress) public view returns (bool) {
        bool ind = false;
        uint256 len = s_allowList.length;
        for (uint256 i = 0; i < len; ++i) {
            if (contributorAddress == s_allowList[i]) {
                ind = true;
                break;
            }
        }
        return ind;
    }
}
