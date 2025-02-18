// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedInventory {

    // Structure pour un article dans l'inventaire
    struct Item {
        string name;
        uint256 quantity;
        string status; // ex: "disponible", "epuise", "reserve"
        uint256 price; // Prix de l'article (en wei ou tokens)
        uint256 timestamp; // Date d'ajout ou de mise à jour de l'article
    }

    // Mapping de l'adresse de l'utilisateur à son inventaire
    mapping(address => mapping(uint256 => Item)) private inventories; 
    mapping(address => uint256) private inventoryCount; // Compteur d'articles pour chaque utilisateur

    // Limites pour les prix et quantités des articles (ce ne sont plus des constantes)
    uint256 public MAX_QUANTITY = 1000;  // Quantité maximale par article
    uint256 public MAX_PRICE = 100 ether;  // Prix maximal par article (exprimé en wei)

    // Protection contre les attaques de reentrance
    bool private locked;
    
    modifier nonReentrant() {
        require(!locked, "Action en cours");
        locked = true;
        _;
        locked = false;
    }

    // Controles d'acces : Seul le proprietaire peut modifier son inventaire
    modifier onlyOwner(uint256 itemId) {
        require(inventories[msg.sender][itemId].timestamp != 0, "Article inexistant.");
        _;
    }

    // Evenements pour le suivi des actions
    event ItemAdded(address indexed owner, uint256 itemId, string name, uint256 quantity, uint256 price);
    event ItemUpdated(address indexed owner, uint256 itemId, uint256 quantity, string status);
    event ItemRemoved(address indexed owner, uint256 itemId);

    // Ajouter un article a l'inventaire avec des controles de securite
    function addItem(string memory name, uint256 quantity, uint256 price) public nonReentrant {
        require(quantity > 0 && quantity <= MAX_QUANTITY, "Quantite invalide.");
        require(price > 0 && price <= MAX_PRICE, "Prix invalide.");
        
        uint256 itemId = inventoryCount[msg.sender]; // Id unique de l'article (par utilisateur)
        inventories[msg.sender][itemId] = Item(name, quantity, "disponible", price, block.timestamp); // Ajout de l'article
        inventoryCount[msg.sender]++; // Incrementation du compteur d'articles pour l'utilisateur

        emit ItemAdded(msg.sender, itemId, name, quantity, price); // Emission de l'evenement
    }

    // Mettre a jour un article dans l'inventaire (seulement proprietaire)
    function updateItem(uint256 itemId, uint256 quantity, string memory status) public onlyOwner(itemId) nonReentrant {
        require(quantity <= MAX_QUANTITY, "Quantite trop elevee.");
        require(bytes(status).length > 0, "Statut invalide.");
        
        inventories[msg.sender][itemId].quantity = quantity; // Mise a jour de la quantite
        inventories[msg.sender][itemId].status = status; // Mise a jour du statut
        inventories[msg.sender][itemId].timestamp = block.timestamp; // Mise a jour du timestamp

        emit ItemUpdated(msg.sender, itemId, quantity, status); // Emission de l'evenement
    }

    // Supprimer un article de l'inventaire (seulement proprietaire)
    function removeItem(uint256 itemId) public onlyOwner(itemId) nonReentrant {
        delete inventories[msg.sender][itemId]; // Suppression de l'article de l'inventaire

        emit ItemRemoved(msg.sender, itemId); // Emission de l'evenement
    }

    // Consulter l'inventaire complet d'un utilisateur
    function getInventory() public view returns (Item[] memory) {
        uint256 itemCount = inventoryCount[msg.sender];
        Item[] memory items = new Item[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            items[i] = inventories[msg.sender][i]; // Recuperation des articles
        }

        return items;
    }

    // Consulter un article specifique dans l'inventaire d'un utilisateur
    function getItem(address owner, uint256 itemId) public view returns (Item memory) {
        require(itemId < inventoryCount[owner], "Article non existant.");
        return inventories[owner][itemId];
    }

    // Fonction d'administration pour ajuster les limites si necessaire
    function setLimits(uint256 maxQuantity, uint256 maxPrice) public {
        require(maxQuantity > 0 && maxPrice > 0, "Limites invalides.");
        MAX_QUANTITY = maxQuantity; // Mise a jour de la limite de quantite
        MAX_PRICE = maxPrice; // Mise a jour de la limite de prix
    }
}


