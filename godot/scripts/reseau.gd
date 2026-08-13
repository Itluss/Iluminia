class_name Reseau
extends Node
## SQUELETTE MULTIJOUEUR (v2) — NON ACTIVÉ EN V1.
##
## Ce fichier documente où et comment brancher un multijoueur WebSocket sans
## réécrire le jeu. La séparation logique est déjà en place :
##   - arene.gd    : état de l'arène (manches, dragon, zones, scores) — future
##                   AUTORITÉ serveur.
##   - chasseur.gd : entrées et état d'UN chasseur — instanciable N fois ; les
##                   bots (_ia_*) deviennent des joueurs distants.
##   - hud.gd/fx.gd : purement locaux, jamais synchronisés.
##
## ---------------------------------------------------------------------------
## ARCHITECTURE CIBLE (serveur relais)
## ---------------------------------------------------------------------------
## 1. Héberger un petit serveur Godot headless (ou Node.js) sur Render/Fly.io :
##    l'export « Linux Server » de ce même projet peut servir de binaire, lancé
##    avec `--headless -- --serveur`. GitHub Pages ne servant que du statique,
##    le serveur DOIT être externe (Render : service web Docker, port 443 en
##    WSS obligatoire depuis une page HTTPS).
##
## 2. Côté serveur (dans _ready si l'argument --serveur est présent) :
##      var pair := WebSocketMultiplayerPeer.new()
##      pair.create_server(8080)
##      multiplayer.multiplayer_peer = pair
##      multiplayer.peer_connected.connect(_sur_connexion)    # créer un Joueur
##      multiplayer.peer_disconnected.connect(_sur_deconnexion)
##
## 3. Côté client (remplacer le câblage direct de main.gd) :
##      var pair := WebSocketMultiplayerPeer.new()
##      pair.create_client("wss://iluminia-relais.onrender.com")
##      multiplayer.multiplayer_peer = pair
##
## 4. Réplication :
##    - Chaque Chasseur devient une scène avec MultiplayerSynchronizer
##      (position, énergie, score, choix) ; l'autorité d'entrée est le pair
##      propriétaire (set_multiplayer_authority(id_pair)).
##    - L'arène (manches, question, dragon, cristaux) n'est simulée QUE par
##      le serveur ; les clients reçoivent les états via MultiplayerSpawner
##      sur le nœud Arene (apparition du Dragon et des cristaux).
##    - Les pouvoirs deviennent des RPC : le client envoie l'intention
##      (`@rpc("any_peer") func demander_onde()`), le serveur valide
##      (cooldown, position, cône) puis diffuse l'effet — idem pour le choix
##      de réponse et la tentative de zone.
##
## 5. Ce qui reste local : FX, Audio, HUD, la caméra — brancher sur les
##    signaux répliqués, jamais l'inverse.
##
## ---------------------------------------------------------------------------
## POURQUOI RIEN N'EST ACTIF ICI
## ---------------------------------------------------------------------------
## La v1 est strictement solo : personne n'instancie ce nœud. Activer le multi
## consiste à : (1) déployer le relais, (2) instancier Reseau dans main.gd
## AVANT la création du monde, (3) transformer les appels directs listés
## ci-dessus en RPC. Aucune autre partie du code n'a besoin de changer.

## URL du futur serveur relais (Render/Fly.io) — à renseigner en v2.
const URL_RELAIS := "wss://a-definir.example.com"


func demarrer_client(_url: String = URL_RELAIS) -> void:
	push_warning("Multijoueur v2 non activé : voir les commentaires de reseau.gd.")


func demarrer_serveur(_port := 8080) -> void:
	push_warning("Multijoueur v2 non activé : voir les commentaires de reseau.gd.")
