pragma solidity 0.8.15;

import { Test } from '@forge-std/Test.sol';
import { CreditRegistry } from '@core/CreditRegistry.sol';
import { ICreditRegistry } from '@interfaces/ICreditRegistry.sol';

contract CreditRegistryTest is Test {

    CreditRegistry registry;
    ICreditRegistry.Term term;

    address DEBTOR_ADDRESS = msg.sender;
    address CONTROLLER_ADDRESS = 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5;
    address MARKET_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address ORACLE_ADDRESS = 0x95A2b07eB236110719975625CeE026ffe2b02799;
    address ROUTER_ADDRESS = 0xC4356aF40cc379b15925Fc8C21e52c00F474e8e9;

    function setUp() public {
        registry = new CreditRegistry(ROUTER_ADDRESS, ORACLE_ADDRESS, CONTROLLER_ADDRESS);
        term = ICreditRegistry.Term.ONE_MONTHS;
    }

    function testOwnership() public {
        _whitelist(MARKET_ADDRESS);
    }

    function testWhitelisting() public {
        _whitelist(MARKET_ADDRESS);

        bool isWhitelisted = registry.isWhitelisted(MARKET_ADDRESS, term);

        _blacklist(MARKET_ADDRESS);

        bool isBlacklisted = !registry.isWhitelisted(MARKET_ADDRESS, term);

        require(isWhitelisted && isBlacklisted);
    }

    function testSectorListing() public {
        bytes32 sectorId = keccak256(".");

        _push(sectorId, MARKET_ADDRESS);

        address[] memory constituents = registry.constituents(sectorId);

        bool isConstituent;

        for (uint256 x = 0; x < constituents.length; x++) {
            if (constituents[x] == MARKET_ADDRESS) isConstituent = true;
        }

        _pull(sectorId, MARKET_ADDRESS);

        constituents = registry.constituents(sectorId);

        bool isNotConstituent = true;

        for (uint256 x = 0; x < constituents.length; x++) {
            if (constituents[x] == MARKET_ADDRESS) isNotConstituent = false;
        }

        require(isConstituent && isNotConstituent);
    }

    function testAugmentationAndSlash() public {
        _configureCriterion(MARKET_ADDRESS, 10000 ether);

        /*  -------- ROUTER -------- */
        vm.startPrank(ROUTER_ADDRESS); 
            registry.augment(DEBTOR_ADDRESS, MARKET_ADDRESS, term, 27504 ether);
            registry.augment(DEBTOR_ADDRESS, MARKET_ADDRESS, term, 10235 ether);
        vm.stopPrank();
        /*  ------------------------ */

        uint256 preCredit = registry.credit(DEBTOR_ADDRESS, MARKET_ADDRESS);

        /*  -------- ROUTER -------- */
        vm.startPrank(ROUTER_ADDRESS); 
            registry.slash(DEBTOR_ADDRESS, MARKET_ADDRESS, term, 9000 ether);
            registry.slash(DEBTOR_ADDRESS, MARKET_ADDRESS, term, 15394 ether);
        vm.stopPrank();
        /*  ------------------------ */

        uint256 postCredit = registry.credit(DEBTOR_ADDRESS, MARKET_ADDRESS);

        require(preCredit == 3 && postCredit == 2);
    }

    function testAttestation() public { }

    function _whitelist(address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.whitelist(asset, term);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _blacklist(address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.blacklist(asset, term);
        vm.stopPrank();
        /*  ------------------------ */ 
    }

    function _configureCriterion(address asset, uint256 criterion) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.configureCriterion(asset, term, criterion);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _push(bytes32 id, address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.push(id, asset);
        vm.stopPrank();
        /*  ------------------------ */
    }

    function _pull(bytes32 id, address asset) internal {
        /*  ------ CONTROLLER ------ */
        vm.startPrank(CONTROLLER_ADDRESS);
            registry.pull(id, asset);
        vm.stopPrank();
        /*  ------------------------ */
    }

}