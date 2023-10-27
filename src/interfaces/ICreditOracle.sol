pragma solidity ^0.8.13;

import "@interfaces/IDomainObjects.sol";

interface ICreditOracle is IDomainObjects {
    
    function log(address asset, Term duration, uint256 interest) external;

}