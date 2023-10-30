// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
REPETIBLE CON LÍMITE, PREMIO POR REFERIDO

* El usuario puede participar en el airdrop una vez por día hasta un límite de 10 veces
* Si un usuario participa del airdrop a raíz de haber sido referido, el que refirió gana 3 días adicionales para poder participar
* El contrato Airdrop mantiene los tokens para repartir (no llama al `mint` )
* El contrato Airdrop tiene que verificar que el `totalSupply`  del token no sobrepase el millón
* El método `participateInAirdrop` le permite participar por un número random de tokens de 1000 - 5000 tokens
*/

interface IMiPrimerTKN {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract AirdropTwo is Pausable, AccessControl {
    // instanciamos el token en el contrato
    IMiPrimerTKN miPrimerToken;


    struct Participante {
        uint256 usos;
        uint256 tiempoEspera;
        uint256 limiteParticipaciones;
    }

    mapping (address => Participante) public participantes;

    constructor(address _tokenAddress) {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function participateInAirdrop() public {
        Participante storage participante = participantes[msg.sender];
        if (participante.usos == 0){
            participante.limiteParticipaciones = 10;
        }
        require(participante.usos < participante.limiteParticipaciones, "Llegaste limite de participaciones");
        require(participante.tiempoEspera < block.timestamp, "Ya participaste en el ultimo dia");

        // pedir número random de tokens
        uint256 tokensToReceive = _getRadomNumber10005000();

        require(tokensToReceive < miPrimerToken.balanceOf(address(this)), "El contrato Airdrop no tiene tokens suficientes");
        participante.usos++;
        participante.tiempoEspera = block.timestamp + 86400;

        // transferir los tokens
        miPrimerToken.transfer(msg.sender, tokensToReceive);
    }

    function participateInAirdrop(address _elQueRefirio) public {
        Participante storage participante = participantes[msg.sender];
        Participante storage referido = participantes[_elQueRefirio];
        if (participante.usos == 0){
            participante.limiteParticipaciones = 10;
        }
        if (referido.usos == 0){
            referido.limiteParticipaciones = 10;
        }
        require(_elQueRefirio != msg.sender, "No puede autoreferirse");
        require(participante.usos < participante.limiteParticipaciones, "Llegaste limite de participaciones");
        require(participante.tiempoEspera < block.timestamp, "Ya participaste en el ultimo dia");

        referido.limiteParticipaciones += 3;

        uint256 tokensToReceive = _getRadomNumber10005000();

        require(tokensToReceive < miPrimerToken.balanceOf(address(this)), "El contrato Airdrop no tiene tokens suficientes");
        participante.usos++;
        participante.tiempoEspera = block.timestamp + 86400;

        miPrimerToken.transfer(msg.sender, tokensToReceive);
    }

    ///////////////////////////////////////////////////////////////
    ////                     HELPER FUNCTIONS                  ////
    ///////////////////////////////////////////////////////////////

    function _getRadomNumber10005000() internal view returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) %
                4000) +
            1000 +
            1;
    }

    function setTokenAddress(address _tokenAddress) external {
        miPrimerToken = IMiPrimerTKN(_tokenAddress);
    }

    function transferTokensFromSmartContract()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        miPrimerToken.transfer(
            msg.sender,
            miPrimerToken.balanceOf(address(this))
        );
    }
}
