// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface DSH {
	function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function get_coins(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface LP {
	function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function mint_to(address to, uint256 amount) external;
	function burn(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external returns (uint256);
    function circ_supply() external view returns (uint256);
}

contract AMM is Ownable {

    DSH public tokenTwo;
    DSH public tokenOne;
    LP public lp;
    uint256 public burned_lp = 0;
    address public pool_owner;
    mapping(address => uint256) public tokenTwo_bal;
    mapping(address => uint256) public tokenOne_bal;

    using SafeMath for uint256;

    constructor (address _dsh, address _tokenOne, address _lp) {
        pool_owner = msg.sender;
        tokenTwo = DSH(_dsh);
        tokenOne = DSH(_tokenOne);
        lp = LP(_lp);
    }

    function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256){
        if (x < y) {
            return x;
        }
        else {
            return y;
        }
    }

    function change_token_A(address addr) public onlyOwner{
        tokenTwo = DSH(addr);
    }

    function change_token_B(address addr) public onlyOwner{
        tokenOne = DSH(addr);
    }

    function change_token_LP(address addr) public onlyOwner{
        lp = LP(addr);
    }

    // Initialise the pool (this sets the price ratio going forward)
    function create_pool(uint256 tokenOne_amt, uint256 tokenTwo_amt) public {
        require(tokenOne.allowance(msg.sender, address(this)) > tokenOne_amt);
        require(tokenTwo.allowance(msg.sender, address(this)) > tokenTwo_amt);
        tokenOne.transferFrom(msg.sender, address(this), tokenOne_amt);
        tokenTwo.transferFrom(msg.sender, address(this), tokenTwo_amt);
        uint256 lp_amt = sqrt(tokenOne_amt.mul(tokenTwo_amt));
        lp.mint_to(msg.sender, lp_amt);
    }

    // Return the balance of the pool (tokenOne, tokenTwo)
    function get_pool_balance() public view returns (uint256, uint256){
        return (tokenOne.balanceOf(address(this)), tokenTwo.balanceOf(address(this)));
    }

    // Deposit liquidity in form of both tokenOne and tokenTwo (by specifying amount of tokenOne)
    // Receive proportional amount of LP tokens in return
    function deposit_liquidity_tokenOne(uint256 tokenOne_amt) public {
        require(tokenOne.allowance(msg.sender, address(this)) > tokenOne_amt);
        uint256 tokenTwo_amt = price_ratio_a(tokenOne_amt);
        require(tokenTwo.allowance(msg.sender, address(this)) > tokenTwo_amt);
        uint256 reserve0 = tokenOne.balanceOf(address(this));
        uint256 reserve1 = tokenTwo.balanceOf(address(this));
        uint256 totalSupply = lp.circ_supply();
        uint256 lp_amt = min(tokenOne_amt.mul(totalSupply) / reserve0, tokenTwo_amt.mul(totalSupply) / reserve1);

        tokenOne.transferFrom(msg.sender, address(this), tokenOne_amt);
        tokenTwo.transferFrom(msg.sender, address(this), tokenTwo_amt);

        lp.mint_to(msg.sender, lp_amt);
    }

    function deposit_view(uint256 tokenOne_amt) public view returns (uint256) {
        uint256 tokenTwo_amt = price_ratio_a(tokenOne_amt);
        uint256 reserve0 = tokenOne.balanceOf(address(this));
        uint256 reserve1 = tokenTwo.balanceOf(address(this));
        uint256 totalSupply = lp.circ_supply();
        uint256 lp_amt = min(tokenOne_amt.mul(totalSupply) / reserve0, tokenTwo_amt.mul(totalSupply) / reserve1);

        return lp_amt;
    }

    // Calculate the price of tokenTwo (with tokenOne unit of account)
    // THIS NEEDS FIXING
    function price_ratio_a(uint256 tokenOne_amt) public view returns (uint256){
        return (tokenOne_amt.mul(tokenTwo.balanceOf(address(this)))).div(tokenOne.balanceOf(address(this)));
    }

    // Calculate the ratio of (amount_deposited) : (total_pool_amount)
    /*
    function ratio_of_pool(uint256 tokenOne_amt) public view returns (uint256){
        (uint256 a, uint256 b) = get_pool_balance();
        return (tokenOne_amt * 10000)/(a + tokenOne_amt);
    }
    */

    // Redeem LP tokens and receive the corresponding amount of tokenOne and tokenTwo
    function redeem_lp(uint256 lp_amt) public {
        require(lp.allowance(msg.sender, address(this)) > lp_amt);
        lp.transferFrom(msg.sender, address(this), lp_amt);
        lp.burn(lp_amt);
        (uint256 a, uint256 b) = redeem_amount(lp_amt);
        tokenOne.transfer(msg.sender, a);
        tokenTwo.transfer(msg.sender, b);
    }

    // View how much you get back with LP tokens
    function redeem_amount(uint256 lp_amt) public view returns (uint256 a_return, uint256 b_return){
        uint256 reserve0 = tokenOne.balanceOf(address(this));
        uint256 reserve1 = tokenTwo.balanceOf(address(this));
        uint256 totalSupply = lp.circ_supply();
        a_return = (lp_amt*reserve0)/totalSupply;
        b_return = (lp_amt*reserve1)/totalSupply;
    }

    // Swap token A for token B
    function swap_atob(uint256 amt_a) public {
        require(tokenOne.allowance(msg.sender, address(this)) > amt_a);
        (uint256 a, uint256 b) = get_pool_balance();
        uint256 k = a*b;
        uint256 m = b.sub(k.div(a+amt_a));
        tokenOne.transferFrom(msg.sender, address(this), amt_a);
        tokenTwo.transfer(msg.sender, m);
    }

    // View the cost of a swap from A to B
    function swap_atob_view(uint256 amt_a) public view returns (uint256){
        (uint256 a, uint256 b) = get_pool_balance();
        uint256 k = a*b;
        uint256 m = b.sub(k.div(a+amt_a));
        return m;
    }

    // Swap token B for token A
    function swap_btoa(uint256 amt_b) public {
        require(tokenTwo.allowance(msg.sender, address(this)) > amt_b);
        (uint256 a, uint256 b) = get_pool_balance();
        uint256 k = a*b;
        uint256 m = a.sub(k.div(b+amt_b));
        tokenOne.transferFrom(msg.sender, address(this), amt_b);
        tokenTwo.transfer(msg.sender, m);
    }

    // View the cost of a swap from B to A
    function swap_btoa(uint256 amt_b) public view returns (uint256) {
        (uint256 a, uint256 b) = get_pool_balance();
        uint256 k = a*b;
        uint256 m = a.sub(k.div(b+amt_b));
        return m;
    }

    /*
    // The following functions do not work (as the contract is approving, not the user)
    // Approve spending for the LP token
    function approve_lp() public {
        lp.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }


    function approve_deposit() public {
        tokenOne.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        tokenTwo.approve(address(this),115792089237316195423570985008687907853269984665640564039457584007913129639935);
    }

        function deposit_tokenOne(uint256 amount) external {
        tokenOne.transferFrom(msg.sender, address(this), amount);
        tokenOne_bal[msg.sender] += amount;
    }

    function deposit_dsh(uint256 amount) external {
        tokenTwo.transferFrom(msg.sender, address(this), amount);
        tokenTwo_bal[msg.sender] += amount;
    }

    function get_tokenOne_balance() public view returns (uint256){
        return (tokenOne_bal[msg.sender]);
    }

    function get_tokenTwo_balance() public view returns (uint256){
        return (tokenTwo_bal[msg.sender]);
    }
    */


}
