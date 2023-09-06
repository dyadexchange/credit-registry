pragma solidity 0.8.15;

import { Test } from '@forge-std/Test.sol';
import { CreditRegistry } from '@core/CreditRegistry.sol';
import { ICreditRegistry } from '@interfaces/ICreditRegistry.sol';

contract CreditRegistryTest is Test {

	CreditRegistry registry;
    ICreditRegistry.Term term;

	address CONTROLLER_ADDRESS = 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5;
	address MARKET_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
	address ORACLE_ADDRESS = 0x95A2b07eB236110719975625CeE026ffe2b02799;
	address ROUTER_ADDRESS = 0xC4356aF40cc379b15925Fc8C21e52c00F474e8e9;
 	
	function setUp() public {
		registry = new CreditRegistry(ROUTER_ADDRESS, ORACLE_ADDRESS, CONTROLLER_ADDRESS);
        term = ICreditRegistry.Term.ONE_MONTHS;
	}

    function testOwnership() public {
        _whitelist_asset(MARKET_ADDRESS);
    }

	function _whitelist_asset(address asset) internal {
        /*  ------ CONTROLLER ------ */
		vm.startPrank(CONTROLLER_ADDRESS);
			registry.whitelist(asset);
		vm.stopPrank();
		/*  ------------------------ */
	}

    function _blacklist_asset(address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.blacklist(asset);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _configure_criterion(address asset, uint256 criterion) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.configureCriterion(asset, term, criterion);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _list_asset(bytes32 id, address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.push(id, asset);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _delist_asset(bytes32 id, address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.pull(id, asset);
        vm.stopPrank();
        /*  ------------------------ */
    }

}