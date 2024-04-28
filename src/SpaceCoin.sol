//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ICO} from "./ICO.sol";

contract SpaceCoin is ERC20 {
    error SpaceCoin__NotOwner();

    address public immutable i_owner;
    //since we do not have function to change the treasury address, it is declared as immutable
    address private immutable i_treasury;
    address private immutable i_icoContract;
    bool public isTaxEnabled;
    uint256 private constant ICO_SUPPLY = 150000;
    uint256 private constant TREASURY_SUPPLY = 350000;
    uint256 public constant TAX_PERCENTAGE = 2;
    uint256 private constant PRECISSION = 10 ** 18;
    // uint256 constant INITIAL_SUPPLY = 500000 * 10**18;

    /**
     * @param _treasury address of the account that will collect the taxes
     *
     */
    constructor(address _treasury, address[] memory allowList) ERC20("SpaceCoin", "SPC") {
        i_owner = msg.sender;
        i_treasury = _treasury;
        i_icoContract = address(new ICO(allowList, i_owner, address(this)));
        isTaxEnabled = false;
        _mint(i_treasury, TREASURY_SUPPLY * PRECISSION);
        _mint(i_icoContract, ICO_SUPPLY * PRECISSION);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert SpaceCoin__NotOwner();
        _;
    }
    /**
     * @dev owner of the contract can decide about collecting of the tax
     */

    function changeTaxStatus() external onlyOwner {
        isTaxEnabled = !isTaxEnabled;
    }

    /**
     * @param sender account sending the token
     * @param recipient account recieving the token
     * @param amount ammount to be transfered
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = 0;
        if (isTaxEnabled) {
            taxAmount = (amount * TAX_PERCENTAGE) / 100;
            super.transferFrom(sender, i_treasury, taxAmount);
        }
        super.transferFrom(sender, recipient, amount - taxAmount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = 0;
        if (isTaxEnabled) {
            taxAmount = (amount * TAX_PERCENTAGE) / 100;
            super.transfer(i_treasury, taxAmount);
        }
        super.transfer(recipient, amount - taxAmount);
        return true;
    }

    function getIcoContractAddress() public view returns (address) {
        return i_icoContract;
    }

    function getTreasuryAddress() public view returns (address) {
        return i_treasury;
    }
}
