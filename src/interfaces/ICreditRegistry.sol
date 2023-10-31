pragma solidity ^0.8.13;

import "@interfaces/IDomainObjects.sol";

interface ICreditRegistry is IDomainObjects {

    struct Market {
        bool whitelist;
        uint256 criterion;
    }

    struct Sector {
        address[] assets;
        mapping(address => uint256) index;
        Term[] durations;
    }
    
    struct Entity {
        mapping (Term => Credit) credit;
    }

    struct Credit {
        uint256 recouped;
        uint256 defaulted;
    }

    error InvalidController();

    error InvalidRouter();

    event Whitelist(address indexed asset);

    event Blacklist(address indexed assset);

    event SectorListing(bytes32 indexed id, address asset);

    event SectorDelisting(bytes32 indexed id, address asset);

    event CriterionChange(address indexed asset, uint256 criterion);

    event ConfigurationChange(address previous, address current);

}