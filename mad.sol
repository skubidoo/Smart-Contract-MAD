// SPDX-License-Identifier: GPL-3.0

//As we move towards a more utopic society, we must find better ways to
//to resolve conflict. This contract takes commitment(value) from neighboring countries
//in hopes of entering into a period of peace and stability between the contracted parties.
//Once entering into commitment the parties will be locked in escrow for a specific period of time.
//They can only exit and renegotiate the contract after the contract has expired.
//If one country wishes to destroy their neighboring country's funds, they must  destroy their own funds as well.
//They can only destroy their neighbor, if they agree to destroy themselves. Mutually Assured Destruction.

pragma solidity >=0.7.0 <0.9.0;

contract MAD{
    address public facilitator;
    
    struct Country {
        address selfAddress;
        bool committed;
        address madWith;
        uint escrow;
    }
    
    address public countryAddressA;
    address public countryAddressB;
    
    uint public contractedEscrow;
    
    mapping(address => Country) public countries;
    
    uint public startBlock;
    uint public endBlock;

    constructor(address _countryA, address _countryB, uint _contractedEscrow, uint _contractDurationWeeks){
        countryAddressA = _countryA;
        countryAddressB = _countryB;
        contractedEscrow = _contractedEscrow;
        facilitator = msg.sender;
        
        countries[_countryA].selfAddress = _countryA;
        countries[_countryA].committed = false;
        countries[_countryA].madWith = _countryB;
        
        
        countries[_countryB].selfAddress = _countryB;
        countries[_countryB].committed = false;
        countries[_countryB].madWith = _countryA;
        
        startBlock = block.number;
        endBlock = startBlock + (_contractDurationWeeks * 40320); //40320; //will run a week.  numOfSecsPerWeek / blockSpawnIntervalSecs         blockSpawnIntervalSecs is 50 seconds
        
        
        
    }
    function getCountry(address _address) view public returns (address, bool, address) {
        return (countries[_address].selfAddress, countries[_address].committed, countries[_address].madWith);
    }
    
    modifier onlyParticipants(){
        require(msg.sender == countries[msg.sender].selfAddress);
        _;
    }
    modifier correctMadWith(address madWith){
        require(countries[msg.sender].madWith == madWith);
        _;
    }
    modifier bothCommitted(address countryCommittedWithAddress){
        require(countries[msg.sender].committed == true && countries[countryCommittedWithAddress].committed == true);
        _;
    }
    modifier meetsMinimumContractedEscrow(address countryCommittedWithAddress){
        require(countries[msg.sender].escrow >= contractedEscrow);
        require(countries[countryCommittedWithAddress].escrow >= contractedEscrow);
        _;
    }
    modifier contractExpired(){
        require(block.number >= endBlock);
        _;
    }
    
    function commit(address country) payable public onlyParticipants correctMadWith(country) {
        require(msg.value >= contractedEscrow);
        countries[msg.sender].committed = true;
        countries[msg.sender].escrow = msg.value;
        
    }
    
    function uncommit(address country) public{
        if(countries[msg.sender].committed == false || countries[country].committed == false){
            returnFunds(country);
        }
    }
    //receive() external payable{
    //    require(msg.value >= contractedEscrow);
    //}
    
    function renegotiate(address country) public onlyParticipants correctMadWith(country) contractExpired{
         returnFunds(country);
    }
    function returnFunds(address country) private{
         if(countries[msg.sender].committed == true){
             sendFunds(msg.sender);
         }
         
         if(countries[country].committed == true){
             sendFunds(country);
         }
         
    }
    function sendFunds(address target) private{
        countries[target].committed = false;
         (bool success, ) = target.call{value:countries[target].escrow}("");
         require(success, "Transfer to other country failed.");
         countries[target].escrow = 0;
    }
    
    function mutuallyDestroy(address country) public onlyParticipants correctMadWith(country) bothCommitted(country) meetsMinimumContractedEscrow(country){
        countries[msg.sender].escrow = 0;
        countries[msg.sender].committed = false;
        countries[country].escrow = 0;
        countries[country].committed = false;
    }
}
