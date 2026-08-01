# POC — Le Pont des Fractions

**Version 1 — conception (2026-07-28).** Périmètre : CM1, compétences FRA-01 → FRA-05, jeu solo, programme par défaut (pas d'analyse de photos).

## Principe de design non négociable

**La compétence est le mécanisme de résolution, jamais un quiz devant une porte.**
Un enfant ne « répond pas à une question pour ouvrir le pont » : il répare le pont *en manipulant des fractions*. Si une mission peut se réécrire « QCM + décor », elle est à rejeter.

Corollaires :
- Pas de chiffres de score scolaire visibles par l'enfant (pas de « 7/10 », pas de « niveau CM1 »). Les progrès se voient dans le monde : le pont avance, le village s'anime.
- L'échec ne punit jamais : une planche mal placée tombe dans la rivière avec un « plouf », le PNJ encourage, on recommence. L'erreur est une information pour le moteur, pas une sanction pour l'enfant.

## Le lieu

**Fondvallon**, un petit village au bord d'une rivière. Le grand pont qui menait vers l'autre rive (où l'on aperçoit le Village des Décimaux, brumeux, inaccessible) s'est effondré. Les villageois ont besoin d'aide pour tout remettre en marche — et, à terme, reconstruire le pont.

Arc narratif du POC : **trois missions = trois étapes de la reconstruction**. La récompense finale du POC est la première travée du pont posée, et la promesse visible de la suite.

## Les PNJ

| PNJ | Rôle | Compétences portées |
|---|---|---|
| **Marta la boulangère** | Premier contact, mission d'accueil | FRA-01, FRA-02 |
| **Bram le charpentier** | Maître d'œuvre du pont, fil rouge du village | FRA-02, FRA-03 |
| **Lior le passeur** | Fait traverser la rivière en barque en attendant le pont | FRA-04, FRA-05 |

Trois PNJ suffisent pour le POC. Ils reviennent d'une mission à l'autre — la familiarité crée l'attachement.

## Les trois missions

### Mission 1 — « Le four de Marta » (FRA-01, FRA-02)

Marta doit livrer des tartes aux ouvriers du pont, mais chacun n'en veut qu'une part précise.

- **Mécanique** : l'enfant découpe des tartes entières en parts égales (2, 3, 4, 6, 8) d'un geste, puis compose la commande de chaque ouvrier (« trois quarts pour Bram »). La commande est affichée en mots *et* en écriture fractionnaire — c'est ainsi que l'écriture ¾ s'installe sans leçon.
- **Réussite** : chaque ouvrier reçoit exactement sa part. Trop ou pas assez → l'ouvrier rend l'assiette en riant, on réessaie.
- **Variabilité** : les commandes sont générées par gabarit (dénominateur, numérateur tirés selon la maîtrise courante). La mission est rejouable sans être identique.

### Mission 2 — « La travée de Bram » (FRA-02, FRA-03)

Le cœur du POC. Bram a préparé la structure de la première travée : une poutre graduée de 0 à 2 unités. Il faut fixer chaque planche à la bonne position.

- **Mécanique** : **la poutre du pont EST la droite graduée**. Chaque planche porte une étiquette (½, ¼, 5/4, …) ; l'enfant la fait glisser le long de la poutre et la cloue. Bien placée → elle se fixe avec un son satisfaisant ; mal placée → elle bascule dans la rivière (plouf), Bram en retaille une.
- **Réussite** : la travée complète tient, l'enfant marche dessus — première récompense spatiale concrète.
- **Variabilité** : graduation (en quarts, en tiers…), fractions demandées, densité des repères affichés (les repères s'espacent quand la maîtrise monte).

### Mission 3 — « La barque de Lior » (FRA-04, FRA-05)

En attendant la fin du pont, Lior fait traverser les villageois, mais sa barque chavire si elle est mal chargée.

- **Mécanique** : chaque caisse porte une fraction ; la barque affiche sa capacité (ex. « au plus 1 »). L'enfant compose des chargements : comparer des fractions de même dénominateur, voir qu'⁵⁄₄ dépasse 1 (la barque s'enfonce dangereusement — feedback immédiat et lisible), décomposer 7/4 en « 1 et ¾ » pour faire deux voyages.
- **Réussite** : tous les villageois traversent, aucune caisse à l'eau.
- **Variabilité** : capacité de la barque, jeu de fractions, nombre de voyages.

## Boucle de session cible (10–15 minutes)

Arrivée au village → un PNJ a du nouveau (indicateur visible) → mission (5–8 min) → récompense dans le monde (le pont avance, un élément du village s'anime) → teaser de la suite. Une session = une mission complète. On optimise pour « l'enfant demande à revenir demain », pas pour la durée de session.

## Modèle de maîtrise (v1 volontairement simple)

- Chaque tentative de mission enregistre, par compétence : réussite/échec des micro-actions (une planche = une donnée FRA-03).
- Maîtrise d'une compétence = 3 réussites récentes consécutives sur des paramètres de difficulté croissants. Non-maîtrise persistante → le moteur resert la compétence sous un autre habillage (gabarits différents de la même mission).
- C'est un compteur, pas un modèle bayésien. On raffinera quand on aura des données réelles.

## Ce que le POC doit prouver

1. L'enfant termine une mission **et demande à rejouer le lendemain** (métrique n° 1 : retour J+1, puis J+7).
2. Les mécaniques « la compétence est le mécanisme » fonctionnent — l'enfant manipule des fractions sans percevoir un exercice.
3. Le modèle de maîtrise simple suffit à faire varier la difficulté sans frustration.

Le tableau de bord parent, l'analyse de photos, les autres régions : **hors périmètre POC**.

## Questions ouvertes

1. Tests utilisateurs : combien d'enfants CM1 accessibles pour tester, et sous quel format (séance filmée avec accord parental, retours parents…) ?
2. Support cible du POC : tablette ? ordinateur ? les deux ? (Impacte le choix de stack — à trancher au chantier suivant.)
3. Direction artistique : placeholder assumé pour le POC, ou un minimum de charme dès la v1 ? (Mon avis : des assets 2D iso de banque + une palette cohérente suffisent pour tester l'envie de rejouer.)
