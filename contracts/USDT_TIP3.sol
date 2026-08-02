// SPDX-License-Identifier: MIT
pragma ton-solidity >= 0.44.0;

/*
  TIP-3 kompatybilny token USDT (upraszczony)
  - decimals = 6
  - initialSupply mintowane w konstruktorze do wskazanego adresu
  - mint/burn możliwe tylko dla ownera (bridge)
  - owner domyślnie podawany w konstruktorze (tu: Twój adres TON)

  Uwaga: To jest przykład developerski. Przed użyciem produkcyjnym należy
  przeprowadzić audyt, dodać pełne sprawdzenia zgodności ze specyfikacją TIP-3
  oraz testy bezpieczeństwa.
*/

contract USDT_TIP3 {
    // metadane tokena
    uint8 public constant decimals = 6;
    string public name;
    string public symbol;

    // właściciel (bridge) uprawniony do mint/burn
    address public owner;

    // podaż i salda
    uint128 public totalSupply;
    mapping(address => uint128) public balanceOf;
    mapping(address => mapping(address => uint128)) public allowance;

    // zdarzenia
    event Transfer(address indexed from, address indexed to, uint128 value);
    event Approval(address indexed owner, address indexed spender, uint128 value);
    event Mint(address indexed to, uint128 value);
    event Burn(address indexed from, uint128 value);

    modifier onlyOwner() {
        require(msg.sender == owner, 101);
        _;
    }

    /*
      Konstruktor:
      - _name, _symbol: metadane
      - recipient: adres, na który zostanie wyemitowana początkowa pula
      - _owner: adres właściciela (bridge) z prawami mint/burn
      - initialSupply: ilość tokenów w najmniejszych jednostkach (czyli USDT * 10^6)
    */
    constructor(string _name, string _symbol, address recipient, address _owner, uint128 initialSupply) public {
        tvm.accept();
        name = _name;
        symbol = _symbol;
        owner = _owner;
        totalSupply = 0;

        if (initialSupply > 0) {
            totalSupply += initialSupply;
            balanceOf[recipient] += initialSupply;
            emit Mint(recipient, initialSupply);
            emit Transfer(address(0), recipient, initialSupply);
        }
    }

    function transfer(address to, uint128 value) public returns (bool) {
        require(to != address(0), 102);
        require(balanceOf[msg.sender] >= value, 103);

        tvm.accept();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint128 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint128 value) public returns (bool) {
        require(to != address(0), 102);
        require(balanceOf[from] >= value, 103);
        require(allowance[from][msg.sender] >= value, 104);

        tvm.accept();
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    // mint - tylko owner
    function mint(address to, uint128 value) public onlyOwner {
        require(to != address(0), 102);
        tvm.accept();
        totalSupply += value;
        balanceOf[to] += value;
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }

    // burn - tylko owner
    function burn(address from, uint128 value) public onlyOwner {
        require(balanceOf[from] >= value, 103);
        tvm.accept();
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Burn(from, value);
        emit Transfer(from, address(0), value);
    }

    // zmiana właściciela
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), 102);
        tvm.accept();
        owner = newOwner;
    }
}
