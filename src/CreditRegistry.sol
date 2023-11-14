pragma solidity ^0.8.13;

import { ICreditOracle } from "@interfaces/ICreditOracle.sol";
import { ICreditRegistry } from "@interfaces/ICreditRegistry.sol";

contract CreditRegistry is ICreditRegistry {

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

    function constituents(bytes32 id) public view returns (address[] memory) {
        return _sectors[id].assets;
    }

    function criterion(address asset, Term duration) public view returns (uint256) {
        return _markets[asset][duration].criterion;
    }

    function isWhitelisted(address asset, Term duration) public view returns (bool) {
        return _markets[asset][duration].whitelist;
    }

    function recouped(address debtor, address asset, Term duration) public view returns (uint256) {
        return _entities[debtor][asset].credit[duration].recouped;
    }

    function defaulted(address debtor, address asset, Term duration) public view returns (uint256) {
        return _entities[debtor][asset].credit[duration].defaulted;
    }

    function credit(address debtor, address asset, Term duration) 
        public 
        view 
        returns (uint256, uint256) 
    {
        uint256 c = criterion(asset, duration);
        uint256 r = recouped(debtor, asset, duration);
        uint256 d = defaulted(debtor, asset, duration);

        return((r - (r % c)) / c,  (d - (d % c)) / c);
    }

    function attest(
        address asset, 
        Term duration, 
        address debtor,
        uint256 interest,
        uint256 principal,
        bool hasDefaulted
    ) 
        public 
        onlyRouter 
    {
        bool hasSufficientPrincipal = criterion(asset, duration) <= principal;

        if (hasSufficientPrincipal) {
            Credit storage rating = _entities[debtor][asset].credit[duration];

            if (hasDefaulted) {
                rating.defaulted += principal;
            } else {
                rating.recouped += principal;

                oracle().log(asset, duration, interest);
            }

            emit Attestation(debtor, asset, duration, principal, hasDefaulted);
        }
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

    function whitelist(address asset, Term duration) public onlyController {
        _markets[asset][duration].whitelist = true;

        emit Whitelist(asset);
    }

    function blacklist(address asset, Term duration) public onlyController {
        _markets[asset][duration].whitelist = false;

        emit Blacklist(asset);
    }

}
