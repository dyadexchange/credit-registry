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

	modifier onlyRouter() {
		if (msg.sender != router()) {
			revert InvalidRouter();
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

	function router() public view returns (address) {
		return _routerAddress;
	}

	function attest(address asset, uint256 interest) public onlyRouter {
		Market storage market = _markets[asset];

		uint256 newWeight = market.weight + 1;
		uint256 newInterestRate = market.interest + interest;
		uint256 newInterestMod = newInterestRate % newWeight;

		newInterestRate = newInterestRate - newInterestMod;

		market.interest = newInterestRate / newWeight;
		market.weight = newWeight;
	}

	function push(bytes32 id, address asset) public onlyController {
		Sector storage sector = _sectors[id];

		sector.index[asset] = sector.assets.length;
		sector.assets.push(asset);
	}

	function pull(bytes32 id, address asset) public onlyController {
		Sector storage sector = _sectors[id];

		uint256 index = sector.index[asset];
		address replacement = sector.assets[sector.assets.length - 1];

		sector.assets[index] = replacement;
		sector.index[asset] = index;
		sector.assets.pop();
 	}

 	function sector(bytes32 id) public view returns (uint256) {
 		Sector storage sector = _sectors[id];

 		 uint256 sectorInterest;
 		 uint256 sectorSize = sector.assets.length;

 		for(uint256 x; x < sectorSize - 1; x++) { 
 			address consitutantAsset = sector.assets[x];
 			uint256 consitutantInterest = interest(consitutantAsset);
 			uint256 consitutantMod = consitutantInterest % (x + 1);

 			sectorInterest += consitutantInterest - consitutantMod;
 		}

 		return sectorInterest;
 	}

}
