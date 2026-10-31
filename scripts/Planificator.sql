/*
    Auteur: Josoa (josoavj sur GitHub)
    Ce script est la source de la base de données du projet Planificator
    Veuillez vous réferer à la documentation ou envoyer un mail à l'auteur si vous avez besoin d'aide
*/

-- Supprimer complètement la base de données
DROP DATABASE IF EXISTS Planificator;

-- Création de la DB
CREATE DATABASE Planificator;
USE Planificator;

-- Table Compte
CREATE TABLE Account (
                         id_compte INT AUTO_INCREMENT PRIMARY KEY,  -- Identifiant unique pour chaque compte
                         nom VARCHAR(70) NOT NULL,
                         prenom VARCHAR(70) NOT NULL,
                         email VARCHAR(100) NOT NULL UNIQUE,
                         username VARCHAR(50) NOT NULL UNIQUE,
                         password VARCHAR(255) NOT NULL,
                         type_compte ENUM('Administrateur', 'Utilisateur') NOT NULL,  -- Type de compte
                         date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- Date de création du compte
                         recovery_code_hash VARCHAR(255) NULL,
                         recovery_code_created_at TIMESTAMP NULL,
                         UNIQUE (nom, prenom)                -- Contrainte d'unicité sur le nom et prénom
);

/*
    Pour la table Account:
    - Il est recommandé d'utiliser un mot de passe crypté: veuillez crypter votre mot de passe en fonction du techno ou langage utilisé
    - Le mot de passe ne doit pas contenir des informations sensibles (Informations personnelles)
    - La base conserve au moins un administrateur et en accepte au maximum trois.
    - Les changements de rôle et suppressions sont réservés aux administrateurs dans l'application.
*/

-- Limiter le nombre de comptes administrateur à trois
DELIMITER $$

CREATE TRIGGER avant_ajout_compte
    BEFORE INSERT ON Account
    FOR EACH ROW
BEGIN
    IF NEW.type_compte = 'Administrateur' AND (SELECT COUNT(*) FROM Account WHERE type_compte = 'Administrateur') >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La limite de 3 comptes Administrateur est atteinte.';
    END IF;
END$$

DELIMITER ;

-- Vérification du mail
DELIMITER $$

CREATE TRIGGER ajout_compte
    BEFORE INSERT ON Account
    FOR EACH ROW
BEGIN
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L\'email doit contenir un "@" et un "."';
    END IF;
END$$

CREATE TRIGGER maj_compte
    BEFORE UPDATE ON Account
    FOR EACH ROW
BEGIN
    IF NEW.email NOT LIKE '%@%.%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L\'email doit contenir un "@" et un "."';
    END IF;
END$$

DELIMITER ;

-- Garde-fous sur les changements de rôle administrateur
DELIMITER $$

CREATE TRIGGER avant_maj_compte
    BEFORE UPDATE ON Account
    FOR EACH ROW
BEGIN
    IF OLD.type_compte != NEW.type_compte AND NEW.type_compte = 'Administrateur'
       AND (SELECT COUNT(*) FROM Account WHERE type_compte = 'Administrateur') >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La limite de 3 comptes Administrateur est atteinte.';
    END IF;
    IF OLD.type_compte = 'Administrateur' AND NEW.type_compte != 'Administrateur'
       AND (SELECT COUNT(*) FROM Account WHERE type_compte = 'Administrateur') <= 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La base doit conserver au moins un administrateur.';
    END IF;
END$$

DELIMITER ;


-- Pour le mot de passe

DELIMITER $$

CREATE TRIGGER avant_ajout_password
    BEFORE INSERT ON Account
    FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.password) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins 8 caractères.';
    END IF;
END$$

CREATE TRIGGER avant_maj_password
    BEFORE UPDATE ON Account
    FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.password) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le mot de passe doit contenir au moins 8 caractères.';
    END IF;
END$$

DELIMITER ;

-- Empêcher la suppression du dernier compte administrateur présent dans la base de données
DELIMITER $$

CREATE TRIGGER avant_suppression_compte_administrateur
    BEFORE DELETE ON Account
    FOR EACH ROW
BEGIN
    IF OLD.type_compte = 'Administrateur' AND (SELECT COUNT(*) FROM Account WHERE type_compte = 'Administrateur') = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La suppression du dernier compte Administrateur est interdite.';
    END IF;
END$$

DELIMITER ;

-- Maintenance intégrée : migration et index de sécurité/authentification.
CREATE TABLE IF NOT EXISTS SchemaMigration (
    version INT NOT NULL PRIMARY KEY,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO SchemaMigration (version) VALUES (1);

/*
   Début du script pour l'ensemble des tables utilisées dans Planificator
    Structuration:
    - Table Client: Pour les informations sur les clients
    - Table Contrat: Pour les informations sur les contrats des clients
    - Table TypeTraitement: Pour les types de traitements prévus pour les clients
    - Table Traitement: Pour les informations sur chaque service choisit par un client dans son contrat
    - Table Planning: Pour les informations sur le planning de chaque service dedié à un client
    - Table PlanningDetails: Pour les détails de chaque planning
    - Table Facture: Pour la facturation de chaque service du client
    - Table Remarque: Ajout d'un remarque et confirmation si un traitement est effectué
    - Table Signalement: Signalement pour un avancement ou décalage
    - Table Historique: Historique des traitements pour chaque client
*/

-- Table Client
CREATE TABLE Client (
                        client_id INT PRIMARY KEY AUTO_INCREMENT,
                        nom VARCHAR(255) NOT NULL,
                        prenom VARCHAR(255),
                        email VARCHAR(255) NOT NULL,
                        telephone VARCHAR(50) NOT NULL,
                        adresse VARCHAR(255) NOT NULL,
                        nif VARCHAR(50),
                        stat VARCHAR(50),
                        date_ajout DATE NOT NULL,
                        categorie ENUM ('Particulier', 'Organisation', 'Société') NOT NULL,
                        axe ENUM ('Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)') NOT NULL
);

# NIF STAT: Valable uniquement pour les sociétés

/*
    Dans le code back-end:
    Si ce n'est pas un particulier alors prénom change en Responsable
*/

CREATE TABLE Contrat (
                         contrat_id INT PRIMARY KEY AUTO_INCREMENT,
                         client_id INT NOT NULL,
                         reference_contrat VARCHAR(20),
                         date_contrat DATE NOT NULL,
                         date_debut DATE NOT NULL,
                         date_fin VARCHAR(50),
                         statut_contrat ENUM ('Actif', 'Terminé', 'Résilié') NOT NULL DEFAULT 'Actif',
                         duree_contrat INT DEFAULT NULL,
                         duree ENUM ('Indeterminée', 'Déterminée') NOT NULL,
                         categorie ENUM ('Nouveau', 'Renouvellement') NOT NULL,
                         FOREIGN KEY (client_id) REFERENCES Client(client_id) ON DELETE CASCADE
);

/*
    Cette partie est à décommenter si vous voulez calculer la duréee du contrat.
    L'opération se fait en fonction de la date de fin et date de début du contrat
    Dans le code, lors de l'ajout du contrat:
    SELECT *, DATEDIFF(date_fin, date_debut) AS duree FROM Contrat;
*/

-- Type de traitement utilisant enum
CREATE TABLE TypeTraitement (
                                id_type_traitement INT PRIMARY KEY AUTO_INCREMENT,
                                categorieTraitement ENUM ('AT: Anti termites', 'PC', 'NI: Nettoyage Industriel', 'RO: Ramassage Ordures'),
                                typeTraitement ENUM('Dératisation (PC)', 'Désinfection (PC)', 'Désinsectisation (PC)', 'Fumigation (PC)', 'Nettoyage industriel (NI)', 'Anti termites (AT)', 'Ramassage ordures (RO)') NOT NULL
);

-- Insertion des types de traitement prédéfinis
INSERT INTO TypeTraitement (id_type_traitement, categorieTraitement, typeTraitement) VALUES
(1, 'PC', 'Dératisation (PC)'),
(2, 'PC', 'Désinfection (PC)'),
(3, 'PC', 'Désinsectisation (PC)'),
(4, 'PC', 'Fumigation (PC)'),
(5, 'NI: Nettoyage Industriel', 'Nettoyage industriel (NI)'),
(6, 'AT: Anti termites', 'Anti termites (AT)'),
(7, 'RO: Ramassage Ordures', 'Ramassage ordures (RO)');



-- Table Traitement
CREATE TABLE Traitement (
                            traitement_id INT PRIMARY KEY AUTO_INCREMENT,
                            contrat_id INT NOT NULL,
                            id_type_traitement INT NOT NULL, 
                            FOREIGN KEY (contrat_id) REFERENCES Contrat(contrat_id) ON DELETE CASCADE,
                            FOREIGN KEY (id_type_traitement) REFERENCES TypeTraitement(id_type_traitement) ON DELETE CASCADE 
);


-- Table Planning
CREATE TABLE Planning (
                          planning_id INT PRIMARY KEY AUTO_INCREMENT,
                          traitement_id INT NOT NULL,
                          date_debut_planification DATE,
                          mois_debut INT,
                          mois_fin INT,
                          duree_traitement INT NOT NULL DEFAULT 12,
                          redondance INT NOT NULL,
                          date_fin_planification DATE,
                          FOREIGN KEY (traitement_id) REFERENCES Traitement(traitement_id) ON DELETE CASCADE
);

-- Table PlanningDetails
CREATE TABLE PlanningDetails (
                                 planning_detail_id INT PRIMARY KEY AUTO_INCREMENT,
                                 planning_id INT NOT NULL,
                                 facture_id INT NULL, -- Nouveau : lien vers la facture groupée
                                 date_planification DATE NOT NULL,
                                 statut ENUM ('Effectué', 'À venir') NOT NULL,
                                 FOREIGN KEY (planning_id) REFERENCES Planning(planning_id) ON DELETE CASCADE
);

/*
    ✅ RELATION CORRECTE:
    - PlanningDetails.planning_id → Planning.planning_id (FK dans PlanningDetails)
    - NE PAS ajouter de FK inverse dans Planning car cela crée une dépendance circulaire
    - L'ordre d'insertion doit être: Planning PUIS PlanningDetails
*/

-- Table Facture (Pour la facturation de chaque service effectué)
CREATE TABLE Facture (
                         facture_id INT PRIMARY KEY AUTO_INCREMENT,
                         planning_detail_id INT NULL, -- Modifié : peut être NULL si groupé
                         reference_facture VARCHAR(30),
                         montant INT NOT NULL,
                         mode ENUM('Chèque', 'Espèce', 'Mobile Money', 'Virement'),
                         etablissement_payeur VARCHAR(50), -- Pour la chèque uniquement
                         date_cheque DATE NULL, -- Valide aussi pour tous
                         numero_cheque VARCHAR(50) NULL,
                         date_traitement DATE NOT NULL,
                         etat ENUM('Payé', 'Non payé', 'À venir') DEFAULT 'Non payé',
                         axe ENUM ('Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)') NOT NULL
);

-- Historique des prix
CREATE TABLE Historique_prix (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    facture_id INT NOT NULL,
    old_amount INT NOT NULL,
    new_amount INT NOT NULL,
    change_date DATETIME NOT NULL,
    changed_by VARCHAR(255) DEFAULT 'System',
    FOREIGN KEY (facture_id) REFERENCES Facture(facture_id) ON DELETE CASCADE
);

-- Table Remarque (Pour confirmer si une traitement a été effectuée)
CREATE TABLE Remarque (
                          remarque_id INT PRIMARY KEY AUTO_INCREMENT,
                          client_id INT NOT NULL,
                          planning_detail_id INT NOT NULL,
                          facture_id INT,
                          contenu TEXT NOT NULL,
                          issue TEXT,
                          action TEXT NOT NULL,
                          date_remarque TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          FOREIGN KEY (facture_id) REFERENCES Facture(facture_id) ON DELETE SET NULL,
                          FOREIGN KEY (client_id) REFERENCES Client(client_id) ON DELETE CASCADE,
                          FOREIGN KEY (planning_detail_id) REFERENCES PlanningDetails(planning_detail_id) ON DELETE CASCADE
);
/*
    contenu pour contenir les remarques effectués
    issue pour un cas isolé, en cas de problème ou erreur lors du traitement
    action pour contenire les actions entrepris à chaque traitement
*/
-- Table Signalement (Pour un signalement d'avancement ou de décalage)
CREATE TABLE Signalement (
                             signalement_id INT PRIMARY KEY AUTO_INCREMENT,
                             planning_detail_id INT NOT NULL,
                             motif TEXT NOT NULL,
                             type ENUM ('Avancement', 'Décalage') NOT NULL,
                             FOREIGN KEY (planning_detail_id) REFERENCES PlanningDetails(planning_detail_id) ON DELETE CASCADE
);


-- Table Historique (Historique des traitements effectués)
CREATE TABLE Historique (
                            historique_id INT PRIMARY KEY AUTO_INCREMENT,
                            facture_id INT NOT NULL,
                            planning_detail_id INT,
                            signalement_id INT,
                            date_historique TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            contenu TEXT NOT NULL,
                            issue TEXT,
                            action TEXT NOT NULL,
                            FOREIGN KEY (planning_detail_id) REFERENCES PlanningDetails(planning_detail_id) ON DELETE SET NULL,
                            FOREIGN KEY (signalement_id) REFERENCES Signalement(signalement_id) ON DELETE SET NULL,
                            FOREIGN KEY (facture_id) REFERENCES Facture(facture_id) ON DELETE CASCADE
);

ALTER TABLE PlanningDetails
    ADD CONSTRAINT fk_planning_details_facture
    FOREIGN KEY (facture_id) REFERENCES Facture(facture_id) ON DELETE SET NULL;

-- Maintenance intégrée au schéma initial.
CREATE INDEX idx_account_username ON Account(username);
CREATE INDEX idx_account_email ON Account(email);
CREATE INDEX idx_account_recovery_code ON Account(recovery_code_hash);
CREATE INDEX idx_client_nom ON Client(nom);
CREATE INDEX idx_client_email ON Client(email);
CREATE INDEX idx_client_nom_prenom ON Client(nom, prenom);
CREATE INDEX idx_client_categorie ON Client(categorie);
CREATE INDEX idx_client_axe ON Client(axe);
CREATE INDEX idx_client_date_ajout ON Client(date_ajout);
CREATE INDEX idx_contrat_client_id ON Contrat(client_id);
CREATE INDEX idx_contrat_statut ON Contrat(statut_contrat);
CREATE INDEX idx_contrat_date_debut ON Contrat(date_debut);
CREATE INDEX idx_contrat_date_fin ON Contrat(date_fin);
CREATE INDEX idx_contrat_client_statut ON Contrat(client_id, statut_contrat);
CREATE INDEX idx_traitement_contrat_id ON Traitement(contrat_id);
CREATE INDEX idx_traitement_type_id ON Traitement(id_type_traitement);
CREATE INDEX idx_traitement_contrat_type ON Traitement(contrat_id, id_type_traitement);
CREATE INDEX idx_planning_traitement_id ON Planning(traitement_id);
CREATE INDEX idx_planning_traitement_date ON Planning(traitement_id, date_debut_planification);
CREATE INDEX idx_planning_date_debut ON Planning(date_debut_planification);
CREATE INDEX idx_planning_date_fin ON Planning(date_fin_planification);
CREATE INDEX idx_planning_redondance ON Planning(redondance);
CREATE INDEX idx_planning_details_planning ON PlanningDetails(planning_id);
CREATE INDEX idx_planning_details_date ON PlanningDetails(date_planification);
CREATE INDEX idx_planning_details_statut ON PlanningDetails(statut);
CREATE INDEX idx_planning_details_planning_date ON PlanningDetails(planning_id, date_planification);
CREATE INDEX idx_facture_planning_detail ON Facture(planning_detail_id);
CREATE INDEX idx_facture_etat ON Facture(etat);
CREATE INDEX idx_facture_axe ON Facture(axe);
CREATE INDEX idx_facture_date_traitement ON Facture(date_traitement);
CREATE INDEX idx_remarque_client ON Remarque(client_id);
CREATE INDEX idx_remarque_planning_detail ON Remarque(planning_detail_id);
CREATE INDEX idx_remarque_facture ON Remarque(facture_id);
CREATE INDEX idx_signalement_planning_detail ON Signalement(planning_detail_id);
CREATE INDEX idx_signalement_type ON Signalement(type);
CREATE INDEX idx_historique_facture ON Historique(facture_id);
CREATE INDEX idx_historique_planning_detail ON Historique(planning_detail_id);
CREATE INDEX idx_historique_signalement ON Historique(signalement_id);
CREATE INDEX idx_historique_date ON Historique(date_historique);
CREATE INDEX idx_historique_prix_facture ON Historique_prix(facture_id);


ANALYZE TABLE Facture, PlanningDetails, Planning, Traitement,
    TypeTraitement, Contrat, Client, Account, Remarque,
    Signalement, Historique, Historique_prix;
