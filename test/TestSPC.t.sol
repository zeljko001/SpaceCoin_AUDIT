//SPDX-License-Identifier:MIT
pragma solidity 0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {ICO} from "../src/ICO.sol";
import {SpaceCoin} from "../src/SpaceCoin.sol";
import {Deploy} from "../script/Deploy.s.sol";

contract TestSPC is Test {

    SpaceCoin public spaceCoin;
    Deploy public deployer;
    ICO public ico;

    uint256 private constant ICO_SUPPLY = 150000;
    uint256 private constant TREASURY_SUPPLY = 350000;
    uint256 private constant PRECISSION = 10**18;
    uint256 private constant STARTING_USER_BALANCE = 1 ether;
    uint256 public constant REEDEM_RATIO = 5;
    uint256 public constant STARTING_USER_BALANCE_OVER_LIMIT = 2000 ether;
    uint256 public constant CONTRIBUTOR_BALANCE_20K = 20000 ether;

    event PhaseChanged(uint256 newPhase);

    function setUp() public {
        deployer = new Deploy();
        (spaceCoin, ico) = deployer.run();
    }

    function testStartingTreasuryAndIcoBalance() public view{
        assertEq(spaceCoin.balanceOf(address(ico)), ICO_SUPPLY*PRECISSION);
        address treasury = spaceCoin.getTreasuryAddress();
        assertEq(spaceCoin.balanceOf(treasury), TREASURY_SUPPLY*PRECISSION);
    }

    function testGetterDoNotRevert() public view {
        //it should be better to make invariant test for this!
        spaceCoin.getIcoContractAddress();
        spaceCoin.getTreasuryAddress();
    }
    
    function testOnlyOwnerCanChangeTaxStatus(address user) public {
        if (user != spaceCoin.i_owner()){
            vm.prank(user);
            vm.expectRevert();
            spaceCoin.changeTaxStatus();
        }
    }
    function testOwnerCanChangeTaxStatus() public {
        bool initialStatus = spaceCoin.isTaxEnabled();
        vm.prank(spaceCoin.i_owner());
        spaceCoin.changeTaxStatus();
        assert(spaceCoin.isTaxEnabled()==!initialStatus);
    }

    function testTaxIsCollected() public {
        vm.prank(spaceCoin.i_owner());
        spaceCoin.changeTaxStatus();

        vm.startPrank(spaceCoin.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        vm.stopPrank();
        address contributor = makeAddr("contributor");
        vm.deal(contributor, STARTING_USER_BALANCE);

        vm.prank(address(ico));
        spaceCoin.approve(address(ico), ICO_SUPPLY*PRECISSION);
        
        vm.startPrank(contributor);
        ico.contribute{value: STARTING_USER_BALANCE}();
        ico.redeem();
        vm.stopPrank();
        assertEq(STARTING_USER_BALANCE*REEDEM_RATIO*98/100,spaceCoin.balanceOf(contributor));
        assertEq(TREASURY_SUPPLY*PRECISSION + STARTING_USER_BALANCE*REEDEM_RATIO*2/100, spaceCoin.balanceOf(spaceCoin.getTreasuryAddress()));
    }
    function testOnlyOwnerCanToggleContributingPaused(address user) public {
        if (user != ico.i_owner()){
            vm.prank(user);
            vm.expectRevert();
            ico.toggleContributePause();
        }
    }
    function testOnlyOwnerCanToggleRedeemingPaused(address user) public {
        if (user != ico.i_owner()){
            vm.prank(user);
            vm.expectRevert();
            ico.toggleRedeemPause();
        }
    }
    function testToggleRedeemAndContributePaused() public {
        bool initialContributePaused = ico.isContributingPaused();
        bool initialRedeemingPaused = ico.isRedeemingPaused();
        vm.startPrank(ico.i_owner());
        ico.toggleContributePause();
        ico.toggleRedeemPause();
        vm.stopPrank();
        assertEq(initialContributePaused, !ico.isContributingPaused());
        assertEq(initialRedeemingPaused, !ico.isRedeemingPaused());
    }

    function testCanNotContributeWhenContributingPaused() public {
        vm.startPrank(ico.i_owner());
        ico.toggleContributePause();
        address contributor = address(2); //address(2) can contribute in seed phase
        vm.deal(contributor, STARTING_USER_BALANCE);
        vm.expectRevert();
        ico.contribute{value:STARTING_USER_BALANCE}();
    }

    function testCanNotRedeemWhenRedeemingPaused() public {
        vm.startPrank(spaceCoin.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        ico.toggleRedeemPause();
        vm.stopPrank();
        address contributor = makeAddr("contributor");
        vm.deal(contributor, STARTING_USER_BALANCE);

        vm.prank(address(ico));
        spaceCoin.approve(address(ico), ICO_SUPPLY*PRECISSION);
        vm.prank(contributor);
        ico.contribute{value: STARTING_USER_BALANCE}();
        vm.prank(contributor);
        vm.expectRevert();
        ico.redeem();
    }

    function testCanNotRedeemInSeedOrGeneralPhase() public {
        address contributor = address(2); //address(2) can contribute in seed phase
        vm.deal(contributor, STARTING_USER_BALANCE);

        vm.prank(address(ico));
        spaceCoin.approve(address(ico), ICO_SUPPLY*PRECISSION);

        vm.prank(contributor);

        ico.contribute{value: STARTING_USER_BALANCE}();
        vm.prank(contributor);
        vm.expectRevert();
        ico.redeem();

        vm.prank(ico.i_owner());
        ico.advancePhase(0);
        vm.expectRevert();
        vm.prank(contributor);
        ico.redeem();

    }

    function testCanNotContributeInSeedPhaseIfNotInAllowList(address contributor) public {
        bool ind = ico.isInAllowList(contributor);
        if (!ind) {
            vm.deal(contributor, STARTING_USER_BALANCE);
            vm.expectRevert();
            ico.contribute{value: STARTING_USER_BALANCE}();
        }
    }

    function testRevertsIfExceedIndividualLimitInSeedPhase() public {
        address contributor = address(2);
        vm.deal(contributor, STARTING_USER_BALANCE_OVER_LIMIT);
        vm.prank(contributor);
        vm.expectRevert();
        ico.contribute{value:STARTING_USER_BALANCE_OVER_LIMIT}();
    }
    function testRevertsIfExceedIndividualLimitInGeneralPhase() public {
        address contributor = address(2);
        vm.deal(contributor, STARTING_USER_BALANCE_OVER_LIMIT);
        vm.prank(contributor);
        ico.contribute{value: STARTING_USER_BALANCE}();
        vm.prank(ico.i_owner());
        ico.advancePhase(0);
        vm.prank(contributor);
        vm.expectRevert();
        ico.contribute{value: STARTING_USER_BALANCE_OVER_LIMIT - STARTING_USER_BALANCE}();
    }

    function testRevertsIfExceedTotalLimit() public {
        vm.startPrank(ico.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        vm.stopPrank();
        address contributor1 = address(4);
        address contributor2 = address(5);
        vm.deal(contributor1, CONTRIBUTOR_BALANCE_20K);
        vm.prank(contributor1);
        ico.contribute{value: CONTRIBUTOR_BALANCE_20K}();
        console.log("Total Contributions:", ico.totalContributions());
        vm.deal(contributor2, CONTRIBUTOR_BALANCE_20K);
        vm.prank(contributor2);
        vm.expectRevert();
        ico.contribute{value: CONTRIBUTOR_BALANCE_20K}();
    }

    function testCanNotRedeemIfDidNotContributed() public {
        address contributor = address(3);
        vm.startPrank(ico.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        vm.stopPrank();
        vm.prank(contributor);
        vm.expectRevert();
        ico.redeem();
    }

    function testCanNotContributeZero() public {
        address contributor = address(2);
        vm.deal(contributor, STARTING_USER_BALANCE);
        vm.prank(contributor);
        vm.expectRevert();
        ico.contribute{value: 0}();
    }

    function testOnlyOwnerCanChangeThePhase(address fakeOwner) public {
        if (fakeOwner != ico.i_owner()) {
            vm.prank(fakeOwner);
            vm.expectRevert();
            ico.advancePhase(0);
        }
    }

    function testRevertsIfAdvancingFromOpenPhase() public {
        vm.startPrank(ico.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        vm.stopPrank();
        vm.prank(ico.i_owner());
        vm.expectRevert();
        ico.advancePhase(2);
    }

    function testBadAdvancing(uint256 phase) public{
        if (phase!=0 && phase!=1) {
            vm.prank(ico.i_owner());
            vm.expectRevert();
            ico.advancePhase(phase);
        }
    }

    function testAdvancingFromSeed() public {
        vm.prank(ico.i_owner());
        ico.advancePhase(0);
        assert(ico.currentPhase() == ICO.Phase.GENERAL);
    }

    function testAdvancingFromGeneral() public {
        vm.startPrank(ico.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);       
        vm.stopPrank();
        assert(ico.currentPhase() == ICO.Phase.OPEN);
    }

    function testTransferSPCAndCollectTax() public {
        address receiver = makeAddr("receiver");
        vm.prank(spaceCoin.i_owner());
        spaceCoin.changeTaxStatus();
        vm.prank(address(ico));
        spaceCoin.approve(address(ico), ICO_SUPPLY*PRECISSION);
        vm.prank(address(ico));
        spaceCoin.transfer(receiver, STARTING_USER_BALANCE);
        assertEq(STARTING_USER_BALANCE*98/100, spaceCoin.balanceOf(receiver));
        assertEq(TREASURY_SUPPLY*PRECISSION + STARTING_USER_BALANCE*2/100, spaceCoin.balanceOf(spaceCoin.getTreasuryAddress()));
    }
}