pragma solidity ^0.8.13;

import { ICreditRegistry } from '@interfaces/ICreditRegistry.sol';

interface ICreditOracle {
    
    function log(address asset, ICreditRegistry.Term duration, uint256 interest) external;

}