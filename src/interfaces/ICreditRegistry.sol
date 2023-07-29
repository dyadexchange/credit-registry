pragma solidity ^0.8.13;

interface ICreditRegistry {
    
    enum Term { ONE_MONTHS, THREE_MONTHS, SIX_MONTHS, TWELVE_MONTHS }

    struct Entity {
        uint256 credit;
        uint256 recoup;
        uint256 debt;
    }

    struct Market {
        uint256 weight;
        uint256 interest;
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

    event InterestChange(address indexed asset, uint256 interest);

    event ConfigurationChange(address controller, address router, address oracle);

}