pragma solidity ^0.8.13;

import { ICreditRegistry } from "@interfaces/ICreditRegistry.sol";

contract CreditRegistry is ICreditRegistry {

	mapping(bytes32 => Sector) _sectors;
	mapping(address => Market) _markets;
	mapping(address => mapping(address => Lender)) _lenders;

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
	}

	function credit(address account, address asset) public view returns (uint256) {
		return _lenders[account][asset].credit;
	}

	function interest(address asset) public view returns (uint256) {
		return _markets[asset].interest;
	}

	function controller() public view returns (address) {
		return _controllerAddress;
	}

	function push(bytes32 memory id, address asset) public onlyController {
		Sector storage sector = _sectors[id];

		sector.index[asset] = sector.assets.length();
		sector.assets.push(asset);
	}

	function pull(bytes32 memory id, address asset) public onlyController {
		Sector storage sector = _sectors[id];

		uint256 index = sectors.index[asset];
		uint256 replacement = sector.assets[sectors.assets.length() - 1];

		sectors.assets[index] = replacement;
		sectors.index[asset] = index;
		sector.assets.pop();
 	}

}
