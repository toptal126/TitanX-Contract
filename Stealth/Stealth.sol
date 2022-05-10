pragma solidity ^0.8.7;
// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface UniswapRouter02 {
    function WETH() external pure returns (address);

    function WBNB() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function addLiquidityBNB(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function factory() external pure returns (address);
}

contract LiquidityLockPersonal is Ownable {
    IERC20 lockedToken;

        uint256 public endOfLockTime;

    constructor(address lockTokenAddress, uint256 _lockTimeStart) {
        lockedToken = IERC20(lockTokenAddress);
        endOfLockTime = _lockTimeStart;
        transferOwnership(tx.origin);
    }

    receive() external payable {}

    function Lock1moreYear() external onlyOwner {
        endOfLockTime = endOfLockTime + 31556926;
    }

    function Lock30moreDays() external onlyOwner {
        endOfLockTime = endOfLockTime + 2592000;
    }

    function LockedTimestamp() public view returns (uint256) {
        return endOfLockTime;
    }

    function claimLockedTokens() external onlyOwner {
        require(block.timestamp >= endOfLockTime, "Token is Locked");
        lockedToken.transfer(msg.sender, lockedToken.balanceOf(address(this)));
    }
}

interface LPToken {
    function sync() external;
}

contract StealthcontractNative is Ownable {
    uint256 public oneNativeChain = 1 * 10**18;
    uint256 public minLockTimeStealth = 60000;

    address public token0;
    address public token1;

    uint256 public tokensForLiquidity0;
    uint256 public tokensForLiquidity1;

    uint256 public launchTime;

    address public lockerLP;

    UniswapRouter02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public finalized;

    event Launch(address owner, address pair);

    constructor(
        ERC20 _token0,
        uint256 _tokensForLiquidity0,
        uint256 _tokensForLiquidity1,
        uint256 _lockTime,
        address _actualDEXRouter
    ) {
        require(_tokensForLiquidity0 > 0, "Token: rate is 0");
        require(_tokensForLiquidity1 > 0, "Token: rate is 0");
        require(
            _lockTime >= (block.timestamp + minLockTimeStealth),
            "Time is too close for unlock"
        );

        
        transferOwnership(tx.origin);
        uniswapV2Router = UniswapRouter02(_actualDEXRouter);
        uniswapV2Pair = getpair(address(_actualDEXRouter),address(_token0),address(getNativeAddr()));
        generateLPLocker(uniswapV2Pair,_lockTime);
        token1 = getNativeAddr();
        token0 = address(_token0);

        tokensForLiquidity0 = _tokensForLiquidity0;
        tokensForLiquidity1 = _tokensForLiquidity1;

        ERC20(token0).approve(address(uniswapV2Router),  2 ** 255);
       
    }

    receive() external payable {}

    function launchSteahlth() external onlyOwner{
        uint tolerance0 = ERC20(token0).balanceOf(address(this)) - (ERC20(token0).balanceOf(address(this)) * 10 / 100);
        uint tolerance1 = address(this).balance - (address(this).balance * 10 / 100);

        try uniswapV2Router.addLiquidityETH{value:address(this).balance}(address(token0), uint(ERC20(token0).balanceOf(address(this))), tolerance1, tolerance0, address(lockerLP), block.timestamp + (300)) {

        }catch (bytes memory reason) {
            uniswapV2Router.addLiquidityBNB{value: address(this).balance}(address(token0), uint(ERC20(token0).balanceOf(address(this))), tolerance1, tolerance0, address(lockerLP), block.timestamp + (300));
        }

            finalized=true;
            launchTime = block.timestamp;
            emit Launch(msg.sender,uniswapV2Pair );
            LPToken(uniswapV2Pair).sync();
    }

    function getNativeAddr() public view returns (address){
        try uniswapV2Router.WETH() {
            return uniswapV2Router.WETH();
        }
        catch (bytes memory reason) {
            return uniswapV2Router.WBNB();
        }
    }

    function withdrawFunds() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        ERC20(token0).transfer(msg.sender,ERC20(token0).balanceOf(address(this)));
    }

    function generateLPLocker(address _pair, uint256 _lockTime) internal {
        LiquidityLockPersonal createNewLock;
        createNewLock = new LiquidityLockPersonal(
            _pair,
            _lockTime
        );
        lockerLP = address(createNewLock);
    }

    function getpair(address _router, address _token0, address _token1) public returns (address) {
        if (IUniswapV2Factory(UniswapRouter02(_router).factory()).getPair(_token0, _token1) != address(0)) {
            return IUniswapV2Factory(UniswapRouter02(_router).factory()).getPair(_token0, _token1);
        } else {
            return IUniswapV2Factory(UniswapRouter02(_router).factory()).createPair(_token0, _token1);
        }
    }



}


contract StealthcontractIndividualTokens is Ownable {
    uint256 public oneNativeChain = 1 * 10**18;
    uint256 public minLockTimeStealth = 60000;

    address public token0;
    address public token1;

    uint256 public tokensForLiquidity0;
    uint256 public tokensForLiquidity1;

    uint256 public launchTime;

    address public lockerLP;

    UniswapRouter02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool public finalized;

    event Launch(address owner, address pair);

    constructor(
        ERC20 _token0,
        ERC20 _token1,
        uint256 _tokensForLiquidity0,
        uint256 _tokensForLiquidity1,
        uint256 _lockTime,
        address _actualDEXRouter
    ) {
        require(_tokensForLiquidity0 > 0, "Token: rate is 0");
        require(_tokensForLiquidity1 > 0, "Token: rate is 0");
        require(
            _lockTime >= (block.timestamp + minLockTimeStealth),
            "Time is too close for unlock"
        );

        
        transferOwnership(tx.origin);
        uniswapV2Router = UniswapRouter02(_actualDEXRouter);
        uniswapV2Pair = getpair(address(_actualDEXRouter),address(_token0),address(_token1));
        generateLPLocker(uniswapV2Pair,_lockTime);

        token0 = address(_token0);
        token1 = address(_token1);

        tokensForLiquidity0 = _tokensForLiquidity0;
        tokensForLiquidity1 = _tokensForLiquidity1;

        ERC20(token0).approve(address(uniswapV2Router),  2 ** 255);
        ERC20(token1).approve(address(uniswapV2Router),  2 ** 255);
       
    }

    receive() external payable {}

    function launchSteahlth() external onlyOwner{
        uint tolerance0 = ERC20(token0).balanceOf(address(this)) - (ERC20(token0).balanceOf(address(this)) * 10 / 100);
        uint tolerance1 = ERC20(token1).balanceOf(address(this)) - (ERC20(token1).balanceOf(address(this)) * 10 / 100);

    
        UniswapRouter02(uniswapV2Router).addLiquidity(
            address(token0),
            address(token1),
            uint(ERC20(token0).balanceOf(address(this))),
            uint(ERC20(token1).balanceOf(address(this))),
            tolerance0,
            tolerance1,
            address(lockerLP),
            block.timestamp + (300));

            finalized=true;
            launchTime = block.timestamp;
            LPToken(uniswapV2Pair).sync();
            emit Launch(msg.sender,uniswapV2Pair );
    }

    function withdrawFunds() external onlyOwner{
        ERC20(token1).transfer(msg.sender,ERC20(token1).balanceOf(address(this)));
        ERC20(token0).transfer(msg.sender,ERC20(token0).balanceOf(address(this)));
    }

    function generateLPLocker(address _pair, uint256 _lockTime) internal {
        LiquidityLockPersonal createNewLock;
        createNewLock = new LiquidityLockPersonal(
            _pair,
            _lockTime
        );
        lockerLP = address(createNewLock);
    }

    function getpair(address _router, address _token0, address _token1) public returns (address) {
        if (IUniswapV2Factory(UniswapRouter02(_router).factory()).getPair(_token0, _token1) != address(0)) {
            return IUniswapV2Factory(UniswapRouter02(_router).factory()).getPair(_token0, _token1);
        } else {
            return IUniswapV2Factory(UniswapRouter02(_router).factory()).createPair(_token0, _token1);
        }
    }



}

interface StorageContract {
    function addProject(
        uint256 _startTime,
        uint256 _endTime,
        address _projectAddress,
        string memory _name
    ) external;
}

contract StealthDeployer is Ownable {
    StorageContract store;
    uint256 public steahlthFee;
    uint256 public steahlthCounter;


    address public DAOContract;


    constructor(StorageContract _store) {
        store = _store;
    }

    function createStealthIndividualTokens(
        ERC20 _token0,
        ERC20 _token1,
        uint256 _tokensForLiquidity0,
        uint256 _tokensForLiquidity1,
        uint256 _lockTime,
        address _actualDEXRouter
    ) public payable {
        if(steahlthFee > 0){
            require(msg.value >= steahlthFee, "Please pay the fee");
            (bool sent, bytes memory data) = payable(DAOContract).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }

        StealthcontractIndividualTokens stealthContract;
        stealthContract = new StealthcontractIndividualTokens(
            _token0,
            _token1,
            _tokensForLiquidity0,
            _tokensForLiquidity1,
            _lockTime,
            _actualDEXRouter
        );

        require(_token0.transferFrom(msg.sender, address(stealthContract), _tokensForLiquidity0), "Need more tokens");
        require(_token1.transferFrom(msg.sender, address(stealthContract), _tokensForLiquidity1), "Need more tokens");

        store.addProject(block.timestamp, _lockTime, address(stealthContract), "individual");
        steahlthCounter++;

    }

    function createStealthNative(
        ERC20 _token0,
        uint256 _tokensForLiquidity0,
        uint256 _tokensForLiquidity1,
        uint256 _lockTime,
        address _actualDEXRouter
    ) public payable {
        if(steahlthFee > 0){
            require(msg.value >= steahlthFee, "Please pay the fee");
            (bool sent, bytes memory data) = payable(DAOContract).call{value: steahlthFee}("");
            require(sent, "Failed to send Ether");
        }

        uint256 valueAdded = msg.value - steahlthFee;

        StealthcontractNative stealthContract;
        stealthContract = new StealthcontractNative(
            _token0,
            _tokensForLiquidity0,
            _tokensForLiquidity1,
            _lockTime,
            _actualDEXRouter
        );

        (bool sentToContract, bytes memory dataRequest) = payable(address(stealthContract)).call{value: valueAdded}("");
            require(sentToContract, "Failed to send Ether");

        require(_token0.transferFrom(msg.sender, address(stealthContract), _tokensForLiquidity0), "Need more tokens");

        store.addProject(block.timestamp, _lockTime, address(stealthContract), "native");
        steahlthCounter++;

    }

    function setDAOContract(address _contract) external onlyOwner {
        DAOContract = _contract;
    }

    function changesteahlthFee(uint256 _new) external onlyOwner {
        steahlthFee = _new;
    }

    function changeStorage(address _newStorage) external onlyOwner {
        store = StorageContract(_newStorage);
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
}
