pragma solidity ^0.8.13;

import { ICreditRegistry } from '@interfaces/ICreditRegistry.sol';

interface ICreditOracle is ICreditRegistry {
    
    function log(address asset, Term duration, uint256 interest) external;

}