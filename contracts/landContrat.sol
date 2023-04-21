// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Land {
    address contractOwner;

    constructor() public{
        contractOwner = msg.sender;
    }

    struct Landreg {
        uint id;
        uint area;
        string landAddress;
        uint landPrice;
        string allLatitudeLongitude;
        //string allLongitude;
        string physicalSurveyNumber;
        bool isforSell;
        address payable ownerAddress;
        bool isLandVerified;
    }

    struct User{
        address id;
        string name;
        uint age;
        string city;
        string email;
        bool isUserVerified;
        address payable prosumerAdd;
    }

    struct LandInspector {
        uint id;
        address _addr;
        string name;
        uint age;
        string designation;
        string city;
    }

    struct LandRequest{
        uint reqId;
        address payable sellerId;
        address payable buyerId;
        uint landId;
        reqStatus requestStatus;
        bool isPaymentDone;
    }
    enum reqStatus {requested,accepted,rejected,paymentdone,commpleted}


    uint inspectorsCount;
    uint public userCount;
    uint public landsCount;
    uint public documentId;
    uint requestCount;


    mapping(address => LandInspector) public InspectorMapping;
    mapping(uint => address[]) allLandInspectorList;
    mapping(address => bool)  RegisteredInspectorMapping;
    mapping(address => User) public UserMapping;
    mapping(uint => address)  AllUsers;
    mapping(uint => address[])  allUsersList;
    mapping(address => bool)  RegisteredUserMapping;
    mapping(address => uint[])  MyLands;
    mapping(uint => Landreg) public lands;
    mapping(uint => LandRequest) public LandRequestMapping;
    mapping(address => uint[])  MyReceivedLandRequest;
    mapping(address => uint[])  MySentLandRequest;
    mapping(uint => uint[])  allLandList;
    mapping(uint => uint[])  paymentDoneList;


    function isContractOwner(address _addr) public view returns(bool){
        if(_addr==contractOwner)
            return true;
        else
            return false;
    }

    function changeContractOwner(address _addr)public {
        require(msg.sender==contractOwner,"you are not contractOwner");

        contractOwner=_addr;
    }

    //-----------------------------------------------LandInspector-----------------------------------------------

    function addLandInspector(address _addr,string memory _name, uint _age, string memory _designation,string memory _city) public returns(bool){
        if(contractOwner!=msg.sender)
            return false;
        require(contractOwner==msg.sender);
        RegisteredInspectorMapping[_addr]=true;
        allLandInspectorList[1].push(_addr);
        InspectorMapping[_addr] = LandInspector(inspectorsCount,_addr,_name, _age, _designation,_city);
        return true;
    }

    function ReturnAllLandIncpectorList() public view returns(address[] memory)
    {
        return allLandInspectorList[1];
    }

    function removeLandInspector(address _addr) public{
        require(msg.sender==contractOwner,"You are not contractOwner");
        require(RegisteredInspectorMapping[_addr],"Land Inspector not found");
        RegisteredInspectorMapping[_addr]=false;


        uint len=allLandInspectorList[1].length;
        for(uint i=0;i<len;i++)
        {
            if(allLandInspectorList[1][i]==_addr)
            {
                allLandInspectorList[1][i]=allLandInspectorList[1][len-1];
                allLandInspectorList[1].pop();
                break;
            }
        }
    }

    function isLandInspector(address _id) public view returns (bool) {
        if(RegisteredInspectorMapping[_id]){
            return true;
        }else{
            return false;
        }
    }

    



    //-----------------------------------------------User-----------------------------------------------

    function isUserRegistered(address _addr) public view returns(bool)
    {
        if(RegisteredUserMapping[_addr]){
            return true;
        }else{
            return false;
        }
    }

    function registerUser(string memory _name, uint _age, string memory _city, string memory _email
    ) public {

        require(!RegisteredUserMapping[msg.sender]);

        RegisteredUserMapping[msg.sender] = true;
        userCount++;
        allUsersList[1].push(msg.sender);
        AllUsers[userCount]=msg.sender;
        UserMapping[msg.sender] = User(msg.sender, _name, _age, _city,_email, false,msg.sender);
        //emit Registration(msg.sender);
    }

    function verifyUser(address _userId) public{
        require(isLandInspector(msg.sender));
        UserMapping[_userId].isUserVerified=true;
        UserMapping[_userId].prosumerAdd=msg.sender;
    }
    function isUserVerified(address id) public view returns(bool){
        return UserMapping[id].isUserVerified;
    }
    function ReturnAllUserList() public view returns(address[] memory)
    {
        return allUsersList[1];
    }

    //-----------------------------------------------Land-----------------------------------------------

    function addLand(uint energy, string memory _address, uint energyPrice,string memory _allLatiLongi, string memory name) public {
        require(isUserVerified(msg.sender));
        landsCount++;
        lands[landsCount] = Landreg(landsCount, energy, _address, energyPrice,_allLatiLongi, name,true,msg.sender,false);
        MyLands[msg.sender].push(landsCount);
        allLandList[1].push(landsCount);

        // //verify
        // require(isLandInspector(msg.sender));
        //lands[landsCount].isLandVerified=true;

        // //make for sell
        // require(lands[id].ownerAddress==msg.sender);
        //lands[landsCount].isforSell=true;

        //make for buy
        requestCount++;
        LandRequestMapping[requestCount]=LandRequest(requestCount,UserMapping[msg.sender].prosumerAdd,lands[landsCount].ownerAddress,landsCount,reqStatus.requested,false);
        MyReceivedLandRequest[UserMapping[msg.sender].prosumerAdd].push(requestCount);
        MySentLandRequest[msg.sender].push(requestCount);

        // //approve
        // LandRequestMapping[_requestId].requestStatus=reqStatus.accepted;

        // //reject
        // LandRequestMapping[_requestId].requestStatus=reqStatus.rejected;
    }

    function ReturnAllLandList() public view returns(uint[] memory)
    {
        return allLandList[1];
    }

    function verifyLand(uint _id) public{
        require(isLandInspector(msg.sender));
        lands[_id].isLandVerified=true;
    }
    function isLandVerified(uint id) public view returns(bool){
        return lands[id].isLandVerified;
    }

    function myAllLands(address id) public view returns( uint[] memory){
        return MyLands[id];
    }


    function makeItforSell(uint id) public{
        require(lands[id].ownerAddress==msg.sender);
        lands[id].isforSell=true;
    }

    function requestforBuy(uint _landId) public
    {
        require(isUserVerified(msg.sender) && isLandVerified(_landId));
        requestCount++;
        LandRequestMapping[requestCount]=LandRequest(requestCount,lands[_landId].ownerAddress,msg.sender,_landId,reqStatus.requested,false);
        MyReceivedLandRequest[lands[_landId].ownerAddress].push(requestCount);
        MySentLandRequest[msg.sender].push(requestCount);
    }

    function myReceivedLandRequests() public view returns(uint[] memory)
    {
        return MyReceivedLandRequest[msg.sender];
    }
    function mySentLandRequests() public view returns(uint[] memory)
    {
        return MySentLandRequest[msg.sender];
    }
    function acceptRequest(uint _requestId) public
    {
        require(LandRequestMapping[_requestId].sellerId==msg.sender);
        LandRequestMapping[_requestId].requestStatus=reqStatus.accepted;
    }
    function rejectRequest(uint _requestId) public
    {
        require(LandRequestMapping[_requestId].sellerId==msg.sender);
        LandRequestMapping[_requestId].requestStatus=reqStatus.rejected;
    }

    function requesteStatus(uint id) public view returns(bool)
    {
        return LandRequestMapping[id].isPaymentDone;
    }

    function landPrice(uint id) public view returns(uint)
    {
        return lands[id].landPrice;
    }
    function makePayment(uint _requestId) public payable
    {
        require(LandRequestMapping[_requestId].buyerId==msg.sender && LandRequestMapping[_requestId].requestStatus==reqStatus.accepted);

        LandRequestMapping[_requestId].requestStatus=reqStatus.paymentdone;
        //LandRequestMapping[_requestId].sellerId.transfer(lands[LandRequestMapping[_requestId].landId].landPrice);
        //lands[LandRequestMapping[_requestId].landId].ownerAddress.transfer(lands[LandRequestMapping[_requestId].landId].landPrice);
        lands[LandRequestMapping[_requestId].landId].ownerAddress.transfer(msg.value);
        LandRequestMapping[_requestId].isPaymentDone=true;
        paymentDoneList[1].push(_requestId);
    }

    function returnPaymentDoneList() public view returns(uint[] memory)
    {
        return paymentDoneList[1];
    }

    function makePaymentTestFun(address payable _reveiver) public payable
    {
        _reveiver.transfer(msg.value);
    }
}