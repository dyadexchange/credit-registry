pragma solidity ^0.8.13;

import { ICreditOracle } from "@interfaces/ICreditOracle.sol";
import { ICreditRegistry } from "@interfaces/ICreditRegistry.sol";

contract CreditRegistry is ICreditRegistry {

    mapping(address => bool) _whitelist;
    mapping(bytes32 => Sector) _sectors;
    mapping(address => mapping(Term => Market)) _markets;
    mapping(address => mapping(address => Entity)) _entities;

    address _router;
    address _oracle;
    address _controller;

    constructor(
        address router,
        address oracle,
        address controller
    ) {
        _oracle = oracle;
        _router = router;
        _controller = controller;
    }

    modifier onlyRouter() {
        if (msg.sender != router()) {
            revert InvalidRouter();
        }
        _;
    }

    modifier onlyController() {
        if (msg.sender != controller()) {
            revert InvalidController();
        }
        _;
    }

    function oracle() public view returns (address) {
        return _oracle;
    }

    function router() public view returns (address) {
        return _router;
    }

    function controller() public view returns (address) {
        return _controller;
    }

    function isWhitelisted(address asset) public view returns (bool) {
        return _whitelist[asset];
    }

    function interest(address asset, Term duration) public view returns (uint256) {
        return _markets[asset][duration].interest;
    }

    function criterion(address asset, Term duration) public view returns (uint256) {
        return _markets[asset][duration].criterion;
    }

    function sector(bytes32 id) public view returns (uint256) {
        Sector storage sector = _sectors[id];

         uint256 sectorInterest;
         uint256 sectorSize = sector.assets.length;

        for (uint256 x; x < sectorSize - 1; x++) { 
            Term consitutantTerm = sector.durations[x];

            address consitutantAsset = sector.assets[x];
            uint256 consitutantInterest = interest(consitutantAsset, consitutantTerm);
            uint256 consitutantInterestMod = consitutantInterest % (x + 1);

            sectorInterest += consitutantInterest - consitutantInterestMod;
        }

        return sectorInterest / sectorSize;
    }

    function constitutants(bytes32 id) public view returns (address[] memory) {
        return _sectors[id].assets;
    }

    function recoup(address debtor, address asset) public view returns (uint256) {
        return _entities[debtor][asset].recoup;
    }

    function debt(address debtor, address asset) public view returns (uint256) {
        return _entities[debtor][asset].debt;
    }

    function credit(address debtor, address asset) public view returns (uint256) {
        return _entities[debtor][asset].credit;
    }

    function attest(address asset, Term duration, uint256 interest) public onlyRouter {
        Market storage market = _markets[asset][duration];

        uint256 newWeight = market.weight + 1;
        uint256 newInterest = market.interest + interest;
        uint256 deltaInterestMod = newInterest % newWeight;
        uint256 deltaInterest = newInterest - deltaInterestMod / newWeight;

        ICreditOracle(oracle()).log(asset, duration, interest);

        market.interest = deltaInterest;
        market.weight = newWeight;

        emit InterestChange(asset, deltaInterest);
    }

    function augment(
        address debtor, 
        address asset, 
        Term duration,
        uint256 principal
    ) public onlyRouter {
        Entity storage entity = _entities[asset][debtor];

        uint256 marketCriterion = criterion(asset, duration);
        uint256 deltaCreditMod = principal % marketCriterion;
        uint256 deltaCredit = principal - deltaCreditMod * 1e18 / marketCriterion;

        entity.credit += deltaCredit;
        entity.recoup += principal;

        emit Augment(debtor, entity.credit);
    }

    function slash(
        address debtor, 
        address asset, 
        Term duration,
        uint256 principal
    ) public onlyRouter {
        Entity storage entity = _entities[asset][debtor];

        uint256 marketCriterion = criterion(asset, duration);
        uint256 deltaCreditMod = principal % marketCriterion;
        uint256 deltaCredit = principal - deltaCreditMod * 1e18 / marketCriterion;

        if (entity.credit >= deltaCredit) {
            entity.credit -= deltaCredit;
        }

        entity.debt += principal;

        emit Slash(debtor, entity.credit);
    }

    function configure(address controller, address router, address oracle) public onlyController {
        _controller = controller; 
        _router = router;
        _oracle = oracle;
        
        emit ConfigurationChange(controller, router, oracle);
    }

    function criterion(address asset, Term duration, uint256 criterion) public onlyController {
        _markets[asset][duration].criterion = criterion;

        emit CriterionChange(asset, criterion);
    }

    function push(bytes32 id, address asset) public onlyController {
        Sector storage sector = _sectors[id];

        sector.index[asset] = sector.assets.length;
        sector.assets.push(asset);

        emit SectorListing(id, asset);
    }

    function pull(bytes32 id, address asset) public onlyController {
        Sector storage sector = _sectors[id];

        uint256 index = sector.index[asset];
        address replacement = sector.assets[sector.assets.length - 1];

        sector.assets[index] = replacement;
        sector.index[asset] = index;
        sector.assets.pop();

        emit SectorDelisting(id, asset);
    }

    function whitelist(address asset) public onlyController {
        _whitelist[asset] = true;

        emit Whitelist(asset);
    }

    function blacklist(address asset) public onlyController {
        _whitelist[asset] = false;

        emit Blacklist(asset);
    }

}
