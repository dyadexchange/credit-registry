pragma solidity ^0.8.13;

interface ICreditRegistry {
	
	struct Lender {
		uint256 credit;
		uint256 repaid;
		uint256 lent;
		uint256 debt;
	}

	struct Market {
		uint256 debt;
		uint256 supply;
		uint256 interest;
	}

	struct Sector 
		mapping(address => uint256) index;
		address[] assets;
		uint256 interest;
	}

	error InvalidController();

}