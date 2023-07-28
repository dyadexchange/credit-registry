pragma solidity ^0.8.13;

import { ICreditRegistry } from "@interfaces/ICreditRegistry.sol";

contract CreditRegistry is ICreditRegistry {

    mapping(bytes32 => Sector) _sectors;
    mapping(address => Market) _markets;
    mapping(address => mapping(address => Entity)) _entities;

    address _routerAddress;
    address _controllerAddress;

    constructor(
        address routerAddress,
        address controllerAddress
    ) {
        _routerAddress = routerAddress;
        _controllerAddress = controllerAddress;
    }

    modifier onlyController() {
        if (msg.sender != controller()) {
            revert InvalidController();
        }
        _;
    }

    modifier onlyRouter() {
        if (msg.sender != router()) {
            revert InvalidRouter();
        }
        _;
    }

    function controller() public view returns (address) {
        return _controllerAddress;
    }

    function router() public view returns (address) {
        return _routerAddress;
    }

    function interest(address asset) public view returns (uint256) {
        return _markets[asset].interest;
    }

    function criterion(address asset) public view returns (uint256) {
        return _markets[asset].criterion;
    }

    function isWhitelisted(address asset) public view returns (bool) {
        return _markets[asset].whitelisted;
    }

    function sector(bytes32 id) public view returns (uint256) {
        Sector storage sector = _sectors[id];

         uint256 sectorInterest;
         uint256 sectorSize = sector.assets.length;

        for (uint256 x; x < sectorSize - 1; x++) { 
            address consitutantAsset = sector.assets[x];
            uint256 consitutantInterest = interest(consitutantAsset);
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

    function attest(address asset, uint256 interest) public onlyRouter {
        Market storage market = _markets[asset];

        uint256 newWeight = market.weight + 1;
        uint256 newInterest = market.interest + interest;
        uint256 deltaInterestMod = newInterest % newWeight;
        uint256 deltaInterest = newInterest - deltaInterestMod / newWeight;

        market.interest = deltaInterest;
        market.weight = newWeight;

        emit InterestChange(asset, deltaInterest);
    }

    function augment(address debtor, address asset, uint256 principal) public onlyRouter {
        Entity storage entity = _entities[asset][debtor];

        uint256 marketCriterion = criterion(asset);
        uint256 deltaCreditMod = principal % marketCriterion;
        uint256 deltaCredit = principal - deltaCreditMod * 1e18 / marketCriterion;

        entity.credit += deltaCredit;
        entity.recoup += principal;

        emit Augment(debtor, entity.credit);
    }

    function slash(address debtor, address asset, uint256 principal) public onlyRouter {
        Entity storage entity = _entities[asset][debtor];

        uint256 marketCriterion = criterion(asset);
        uint256 deltaCreditMod = principal % marketCriterion;
        uint256 deltaCredit = principal - deltaCreditMod * 1e18 / marketCriterion;

        if (entity.credit >= deltaCredit) {
            entity.credit -= deltaCredit;
        }

        entity.debt += principal;

        emit Slash(debtor, entity.credit);
    }

    function criterion(address asset, uint256 criterion) public onlyController {
        _markets[asset].criterion = criterion;

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
        _markets[asset].whitelisted = true;

        emit Whitelist(asset);
    }

    function blacklist(address asset) public onlyController {
        _markets[asset].whitelisted = false;

        emit Blacklist(asset);
    }
}
