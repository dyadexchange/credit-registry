pragma solidity ^0.8.13;

import "@interfaces/IDomainObjects.sol";

interface ICreditRegistry is IDomainObjects {
    
    struct Entity {
        uint256 credit;
        uint256 recouped;
        uint256 defaulted;
    }

    struct Market {
        bool whitelist;
        uint256 criterion;
    }

    struct Sector {
        address[] assets;
        mapping(address => uint256) index;
        Term[] durations;
    }

    error InvalidController();

    error InvalidRouter();

    event Whitelist(address indexed asset);

    event Blacklist(address indexed assset);

    event Augment(address indexed entity, uint256 credit);

    event Slash(address indexed entity, uint256 credit);

    event SectorListing(bytes32 indexed id, address asset);

    event SectorDelisting(bytes32 indexed id, address asset);

    event CriterionChange(address indexed asset, uint256 criterion);

    event ConfigurationChange(address previous, address current);

}