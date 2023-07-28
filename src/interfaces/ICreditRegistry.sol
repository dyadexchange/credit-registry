pragma solidity ^0.8.13;

interface ICreditRegistry {
	
	struct Entity {
		uint256 credit;
		uint256 recoup;
		uint256 debt;
	}

	struct Market {
		uint256 weight;
		uint256 interest;
		uint256 criterion;
		bool whitelisted;
	}

	struct Sector {
		mapping(address => uint256) index;
		address[] assets;
		uint256 interest;
	}

	error InvalidController();

	error InvalidRouter();

}