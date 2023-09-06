pragma solidity ^0.8.13;

import { ICreditOracle } from "@interfaces/ICreditOracle.sol";
import { ICreditRegistry } from "@interfaces/ICreditRegistry.sol";

contract CreditRegistry is ICreditRegistry {

    mapping(address => bool) _whitelist;
    mapping(bytes32 => Sector) _sectors;
    mapping(address => mapping(Term => Market)) _markets;
    mapping(address => mapping(address => Entity)) _entities;

    address _router;
    address _controller;

    ICreditOracle _oracle;

    constructor(
        address router,
        address oracle,
        address controller
    ) {
        _router = router;
        _controller = controller;
        _oracle = ICreditOracle(oracle);
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

    function router() public view returns (address) {
        return _router;
    }

    function controller() public view returns (address) {
        return _controller;
    }

    function oracle() public view returns (ICreditOracle) {
        return _oracle;
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
            sectorInterest += interest(sector.assets[x], sector.durations[x]);
        }

        sectorInterest -= sectorInterest % sectorSize;

        return sectorInterest / sectorSize;
    }

    function constituents(bytes32 id) public view returns (address[] memory) {
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

    function attest(address asset, Term duration, uint256 interest) 
        public 
        onlyRouter 
    {
        Market storage market = _markets[asset][duration];

        uint256 deltaWeight = market.weight + 1;
        uint256 culmInterest = market.interest + interest;

        uint256 w = deltaWeight > 2 ? 2 : deltaWeight;

        uint256 deltaInterest = culmInterest / w;

        oracle().log(asset, duration, interest);

        market.interest = deltaInterest;
        market.weight = deltaWeight;

        emit InterestChange(asset, deltaInterest);
    }

    function augment(
        address debtor, 
        address asset, 
        Term duration,
        uint256 principal
    ) 
        public 
        onlyRouter 
    {
        Entity storage entity = _entities[debtor][asset];

        uint256 marketCriterion = criterion(asset, duration);
        uint256 deltaPrincipalMod = principal % marketCriterion;
        uint256 deltaPrincipal = principal - deltaPrincipalMod;
        uint256 deltaCredit = deltaPrincipal / marketCriterion;

        entity.credit += deltaCredit;
        entity.recoup += principal;

        emit Augment(debtor, entity.credit);
    }

    function slash(
        address debtor, 
        address asset, 
        Term duration,
        uint256 principal
    ) 
        public 
        onlyRouter 
    {
        Entity storage entity = _entities[debtor][asset];

        uint256 marketCriterion = criterion(asset, duration);
        uint256 deltaPrincipalMod = principal % marketCriterion;
        uint256 deltaPrincipal = principal - deltaPrincipalMod;
        uint256 deltaCredit = deltaPrincipal / marketCriterion;

        if (entity.credit >= deltaCredit) {
            entity.credit -= deltaCredit;
        }

        entity.debt += principal;

        emit Slash(debtor, entity.credit);
    }

    function configureCriterion(address asset, Term duration, uint256 criterion) 
        public 
        onlyController 
    {
        _markets[asset][duration].criterion = criterion;

        emit CriterionChange(asset, criterion);
    }

    function configureController(address controller) public onlyController {
        address previous = _controller;

        _controller = controller;
        
        emit ConfigurationChange(previous, controller);
    }

    function configureRouter(address router) public onlyController {
        address previous = _router;

        _router = router;
        
        emit ConfigurationChange(previous, router);
    }

    function configureOracle(address oracle) public onlyController {
        address previous = address(_oracle);

        _oracle = ICreditOracle(oracle);
        
        emit ConfigurationChange(previous, oracle);
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
