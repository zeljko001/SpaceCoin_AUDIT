### Issue Summary

| Category      | No. of Issues |
| ------------- | ------------- |
| High          | 1             |
| Medium        | 0             |
| Low           | 0             |
| Informational | 6             |

## HIGH

### [H-1] By calling the function `ICO::redeem()`, tokens should be sent to the contributor based on the ETH that he contributed in the ICO, but using the `SpaceCoin::transferFrom()` function leads to the impossibility of sending a specific quantity of SpaceCoin to contributer.

**Description:** By calling the function `ICO::redeem()`, the user should receive a certain amount of SpaceCoin based on the ETH contributed in the ICO. The problem in the function `ICO::redeem()` occurs when calling the function `SpaceCoin::transferFrom()` in order to transfer a certain value of SpaceCoin to the contributor. Namely, in order to transfer the given value, the `ICO::ico` must allow itself to call the `SpaceCoin::transferFrom()` function to transfer the value to the contributor.

**Impact:** The current situation leads to the fact that the contributor will not be able to extract the intended amount of SpaceCoine in the OPEN phase of ICO when he is allowed to do so, without the ICO first allowing a certain amount to be transferred. In this way, the contributor's right to redeem his SpaceCoins on his own initiative in the OPEN phase is denied.

Problematic part in function `ICO::redeem()` :


```javascript
-->  bool success = spaceCoin.transferFrom(address(this), msg.sender, spcAmount);
        if (success) {
            emit Redeming(msg.sender, spcAmount);
        }
```

**Proof of Concept:**

If we have a contributor from `ICO::s_allowList`, who has contributed 1 ETH, he will not be able to redeem his SpaceCoin in the OPEN phase.

<details>
<summary>PoC</summary>
Place the following test into `TestSPC.t.sol`.

```javascript
 function testCanNotReedem() public {
        address allowListMember = 0x30C816eB8F5701b12687269F2601Cb6ff8A20510;

        vm.deal(allowListMember, STARTING_USER_BALANCE);
        vm.prank(allowListMember);
        ico.contribute{value: STARTING_USER_BALANCE}();
        vm.startPrank(ico.i_owner());
        ico.advancePhase(0);
        ico.advancePhase(1);
        vm.stopPrank();
        vm.prank(allowListMember);
        vm.expectRevert();
        ico.redeem();
    }
```

</details>

**Recommended Mitigation:** There are a few recomendations.

1. Consider using a `SpaceCoin::transfer()` function instead of a function `SpaceCoin::transferFrom()`. This way the `ICO:ico` will not have to allow itself how much SpaceCoin it can send to contributor that want to redeem them.

<details>
<summary>Code example</summary>

```diff
 function redeem() external whenRedeemingNotPaused {
        require(currentPhase == Phase.OPEN, "Reediming is available only in the OPEN phase");
        uint256 contributedEth = userToContributedAmount[msg.sender];
        require(contributedEth > 0, "No contribution to redeem");
        uint256 spcAmount = contributedEth * REEDEM_RATIO;
        userToContributedAmount[msg.sender] = 0;
+       bool success = spaceCoin.transfer(msg.sender, spcAmount);
-       bool success = spaceCoin.transferFrom(address(this), msg.sender, spcAmount);
        if (success) {
            emit Redeming(msg.sender, spcAmount);
        }
    }
```

</details>

2. Consider adding the `SpaceCoin::approve` function before the `SpaceCoin::transferFrom()` to `ICO::redeem()` function.
   
<details>
<summary>Code example</summary>

```diff
 function redeem() external whenRedeemingNotPaused {
        require(currentPhase == Phase.OPEN, "Reediming is available only in the OPEN phase");
        uint256 contributedEth = userToContributedAmount[msg.sender];
        require(contributedEth > 0, "No contribution to redeem");
        uint256 spcAmount = contributedEth * REEDEM_RATIO;
        userToContributedAmount[msg.sender] = 0;
+       spaceCoin.approve(address(this), spcAmount);
        bool success = spaceCoin.transferFrom(address(this), msg.sender, spcAmount);
        if (success) {
            emit Redeming(msg.sender, spcAmount);
        }
    }
```

</details>


## INFORMATIONAL


### [I-1] Public functions not used internally could be marked external

- Found in src/SpaceCoin.sol [Line: 51](src/SpaceCoin.sol#L51)

	```solidity
	    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	```

- Found in src/SpaceCoin.sol [Line: 61](src/SpaceCoin.sol#L61)

	```solidity
	    function transfer(address recipient, uint256 amount) public override returns (bool) {
	```

- Found in src/SpaceCoin.sol [Line: 71](src/SpaceCoin.sol#L71)

	```solidity
	    function getIcoContractAddress() public view returns (address) {
	```

- Found in src/SpaceCoin.sol [Line: 75](src/SpaceCoin.sol#L75)

	```solidity
	    function getTreasuryAddress() public view returns (address) {
	```


## [I-2]: Modifiers invoked only once can be shoe-horned into the function



- Found in src/ICO.sol [Line: 61](src/ICO.sol#L61)

	```solidity
	    modifier withinPhaseLimits(uint256 amount) {
	```

- Found in src/ICO.sol [Line: 80](src/ICO.sol#L80)

	```solidity
	    modifier whenContributingNotPaused() {
	```

- Found in src/ICO.sol [Line: 85](src/ICO.sol#L85)

	```solidity
	    modifier whenRedeemingNotPaused() {
	```

- Found in src/SpaceCoin.sol [Line: 34](src/SpaceCoin.sol#L34)

	```solidity
	    modifier onlyOwner() {
	```


## [I-3]: PUSH0 is not supported by all chains

Solc compiler version 0.8.20 switches the default target EVM version to Shanghai, which means that the generated bytecode will include PUSH0 opcodes. Be sure to select the appropriate EVM version in case you intend to deploy on a chain other than mainnet like L2 chains that may not support PUSH0, otherwise deployment of your contracts will fail.

- Found in src/ICO.sol [Line: 2](src/ICO.sol#L2)

	```solidity
	pragma solidity ^0.8.18;
	```

- Found in src/SpaceCoin.sol [Line: 2](src/SpaceCoin.sol#L2)

	```solidity
	pragma solidity ^0.8.18;
	```

## [I-4]: Openzzepelin `Ownable` which is imported is not according to project specifications. Also, it was not used anywhere in the project. It sholud be removed.

- Found in src/ICO.sol [Line: 4](src/ICO.sol#L4)

	```solidity
	import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
	```


## [I-5]: Solidity pragma should be specific, not wide

Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.18;`, use `pragma solidity 0.8.18;`

- Found in src/ICO.sol [Line: 2](src/ICO.sol#L2)

	```solidity
	pragma solidity ^0.8.18;
	```

- Found in src/SpaceCoin.sol [Line: 2](src/SpaceCoin.sol#L2)

	```solidity
	pragma solidity ^0.8.18;
	```

## [I-6]: `ICO::spaceCoin` address is set once in the constructor and it should be defined as immutable, in order to save gas.


- Found in src/ICO.sol [Line: 22](src/ICO.sol#L22)

	```solidity
	SpaceCoin spaceCoin;
	```