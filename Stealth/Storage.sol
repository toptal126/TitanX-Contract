// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract StealthStore is Ownable {

    mapping(address => bool) public Managers;

    mapping(address => mapping(uint256 => ProjectAttribute)) public ProjectStoreByOwner;
    mapping(address => uint256) public countByOwner;
    address[] public entryListByOwner;

    mapping(address => SearchHelperStruct) public ProjectStoreByPresaleAddress;
    address[] public entryListByPresaleAddress;

    struct SearchHelperStruct{
        address ownerAddress;
        uint256 count;
    }

    struct ProjectAttribute {
        uint256 projectID;

        uint256 projectLaunchTime;
        uint256 lockTime;

        string name;

        address StealthContract;
        address SteahlthCreator;
    }

    constructor() {
        Managers[msg.sender] = true;
    }


    function getProjectsCount() public view returns (uint256 entityCount) {
        return entryListByOwner.length;
    }

    function changeManagerState(address _account, bool _state) external onlyOwner {
        Managers[_account] = _state;
    }


    function addProject(uint256 _startTime, uint256 _endTime, address _projectAddress, string memory _name) public {
        require(Managers[msg.sender], "You are not yet a Manager");

        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].projectID = entryListByOwner.length;
        
        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].projectLaunchTime = _startTime;
        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].lockTime = _endTime;

        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].StealthContract = _projectAddress;
        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].SteahlthCreator = tx.origin;

        ProjectStoreByOwner[tx.origin][countByOwner[tx.origin]].name = _name;
        
        
        ProjectStoreByPresaleAddress[_projectAddress].ownerAddress = tx.origin;
        ProjectStoreByPresaleAddress[_projectAddress].count = countByOwner[tx.origin];

        countByOwner[tx.origin]++;

        entryListByPresaleAddress.push(_projectAddress);
        entryListByOwner.push(tx.origin);
    }


    receive() external payable {
        revert ();
    }
}