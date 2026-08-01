# Référentiel de compétences — Mathématiques CM1–CM2

**Version 1 — brouillon de travail (2026-07-28).**
Basé sur les programmes officiels de l'Éducation nationale (cycle 3, repères annuels CM1/CM2). À vérifier ligne à ligne contre le BO en vigueur avant d'en faire la source de vérité du moteur pédagogique.

## Principes

1. **Le monde représente les compétences, pas les classes.** Une région = un domaine de compétences. L'enfant y revient plusieurs années ; la région s'approfondit, elle ne se périme pas.
2. **Le programme par défaut est le squelette.** Sans photo de cahier, l'enfant suit la progression standard de son niveau. Les photos réordonnent et priorisent, elles ne créent pas le contenu.
3. **Chaque compétence a un identifiant stable** (`NUM-03`, `FRA-02`…). C'est la clé de voûte : les missions, les photos analysées et le suivi parental pointent tous vers ces identifiants.
4. **Les prérequis forment un graphe, pas une liste.** Le jeu utilise les prérequis pour ouvrir/fermer les zones : une compétence non maîtrisée en amont = un pont détruit en aval.

## Carte des régions

| Région | Domaine | Compétences |
|---|---|---|
| Forêt des Nombres | Numération des entiers | NUM |
| Montagnes du Calcul | Les quatre opérations, calcul mental | CAL |
| Pont des Fractions | Fractions | FRA |
| Village des Décimaux | Nombres décimaux | DEC |
| Marché des Mesures | Grandeurs et mesures | MES |
| Temple de la Géométrie | Espace et géométrie | GEO |
| (transversal — présent partout) | Résolution de problèmes | PRB |

La résolution de problèmes n'est pas une région : c'est la matière même des missions. Chaque mission est un problème habillé ; les compétences PRB se travaillent dans toutes les régions.

## Forêt des Nombres (NUM)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| NUM-01 | Lire, écrire, décomposer les entiers jusqu'à 999 999 | ✔ | | (acquis cycle 2) |
| NUM-02 | Lire, écrire, décomposer les entiers jusqu'au milliard | | ✔ | NUM-01 |
| NUM-03 | Comparer, ranger, encadrer des entiers | ✔ | ✔ | NUM-01 |
| NUM-04 | Placer des entiers sur une droite graduée | ✔ | ✔ | NUM-03 |
| NUM-05 | Arrondir un entier (dizaine, centaine, millier) | ✔ | ✔ | NUM-03 |

## Montagnes du Calcul (CAL)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| CAL-01 | Addition et soustraction posées d'entiers | ✔ | | NUM-01 |
| CAL-02 | Tables de multiplication (mémorisation) | ✔ | | (acquis cycle 2, à consolider) |
| CAL-03 | Multiplication posée (multiplicateur à 1 puis 2 chiffres) | ✔ | ✔ | CAL-02 |
| CAL-04 | Division euclidienne (diviseur à 1 chiffre) | ✔ | | CAL-02, CAL-03 |
| CAL-05 | Division euclidienne (diviseur à 2 chiffres) | | ✔ | CAL-04 |
| CAL-06 | Calcul mental : compléments, doubles/moitiés, ×10 ×100 ×1000 | ✔ | ✔ | CAL-01 |
| CAL-07 | Ordre de grandeur et vérification d'un résultat | ✔ | ✔ | NUM-05, CAL-06 |
| CAL-08 | Multiples et diviseurs (notions simples : pair, multiple de 5, de 10…) | | ✔ | CAL-02 |

## Pont des Fractions (FRA)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| FRA-01 | Comprendre une fraction comme partage de l'unité (½, ¼, ⅓…) | ✔ | | NUM-04 |
| FRA-02 | Lire, écrire, nommer des fractions simples | ✔ | | FRA-01 |
| FRA-03 | Placer des fractions simples sur une droite graduée | ✔ | ✔ | FRA-02, NUM-04 |
| FRA-04 | Comparer des fractions de même dénominateur ; les comparer à 1 | ✔ | ✔ | FRA-02 |
| FRA-05 | Décomposer une fraction (partie entière + fraction < 1) | ✔ | ✔ | FRA-04 |
| FRA-06 | Fractions décimales (dixièmes, centièmes) | ✔ | ✔ | FRA-02 |
| FRA-07 | Additionner des fractions de même dénominateur | | ✔ | FRA-04 |

## Village des Décimaux (DEC)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| DEC-01 | Passer de la fraction décimale à l'écriture à virgule et inversement | ✔ | ✔ | FRA-06 |
| DEC-02 | Lire, écrire, décomposer des décimaux (jusqu'au centième, puis millième) | ✔ | ✔ | DEC-01 |
| DEC-03 | Comparer, ranger, encadrer des décimaux | ✔ | ✔ | DEC-02 |
| DEC-04 | Placer des décimaux sur une droite graduée | ✔ | ✔ | DEC-03, NUM-04 |
| DEC-05 | Additionner et soustraire des décimaux | ✔ | ✔ | DEC-02, CAL-01 |
| DEC-06 | Multiplier un décimal par un entier | | ✔ | DEC-05, CAL-03 |
| DEC-07 | Multiplier et diviser un décimal par 10, 100, 1000 | | ✔ | DEC-02, CAL-06 |

## Marché des Mesures (MES)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| MES-01 | Longueurs : unités, conversions, périmètre d'un polygone | ✔ | ✔ | CAL-01 |
| MES-02 | Masses et contenances : unités, conversions | ✔ | ✔ | NUM-03 |
| MES-03 | Durées : lire l'heure, calculer une durée | ✔ | ✔ | CAL-01 |
| MES-04 | Monnaie : rendre la monnaie, situations d'achat | ✔ | ✔ | DEC-05 |
| MES-05 | Aires : comparer, mesurer avec pavage ; unités usuelles | | ✔ | MES-01 |
| MES-06 | Angles : comparer, identifier droit/aigu/obtus | ✔ | ✔ | (aucun) |
| MES-07 | Proportionnalité : situations simples (recettes, prix) | | ✔ | CAL-03, PRB-02 |

## Temple de la Géométrie (GEO)

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| GEO-01 | Vocabulaire et instruments : point, droite, segment, milieu ; règle, équerre, compas | ✔ | | (acquis cycle 2) |
| GEO-02 | Droites perpendiculaires et parallèles : reconnaître, tracer | ✔ | ✔ | GEO-01 |
| GEO-03 | Polygones : identifier et décrire triangles et quadrilatères particuliers | ✔ | ✔ | GEO-01 |
| GEO-04 | Cercle : vocabulaire (centre, rayon, diamètre), tracés au compas | ✔ | ✔ | GEO-01 |
| GEO-05 | Symétrie axiale : reconnaître, compléter une figure | ✔ | ✔ | GEO-01 |
| GEO-06 | Solides : reconnaître, décrire (cube, pavé, pyramide…), patrons simples | ✔ | ✔ | GEO-03 |
| GEO-07 | Se repérer et se déplacer : plans, quadrillages, programmes de déplacement | ✔ | ✔ | (aucun) |

## Résolution de problèmes (PRB) — transversal

| ID | Compétence | CM1 | CM2 | Prérequis |
|---|---|---|---|---|
| PRB-01 | Problèmes à une étape (les quatre opérations) | ✔ | | CAL-01, CAL-03 |
| PRB-02 | Problèmes à deux étapes ou plus | ✔ | ✔ | PRB-01 |
| PRB-03 | Trier les informations utiles d'un énoncé | ✔ | ✔ | PRB-01 |
| PRB-04 | Lire et construire tableaux et graphiques simples | ✔ | ✔ | NUM-03 |
| PRB-05 | Problèmes de proportionnalité | | ✔ | MES-07 |

## Tranche verticale du POC

**Décisions actées (2026-07-28)** : le POC cible le **CM1 uniquement** (les colonnes CM2 restent dans ce référentiel pour la suite). L'analyse de photos de cahiers est reportée à une feature ultérieure — le POC fonctionne entièrement sur le programme par défaut.

Une seule région, un village : le **Pont des Fractions** (FRA-01 → FRA-05, périmètre CM1).

Pourquoi les fractions :
- C'est la difficulté n° 1 identifiée par les parents en CM1 — la valeur du diagnostic y est immédiatement visible.
- Le domaine se prête naturellement au gameplay « la compétence est le mécanisme » : partager, assembler, compléter des morceaux pour réparer le pont — pas un quiz plaqué sur une porte.
- La chaîne de prérequis vers les décimaux (FRA-06 → DEC-01) donne la suite évidente : le Village des Décimaux est la deuxième région, déjà visible de l'autre côté du pont.

**Décision à valider par Camille** : région du POC, noms des régions, découpage des compétences.

## Questions ouvertes

1. Granularité : ce référentiel (~45 compétences) est-il au bon grain pour générer des missions, ou faut-il un sous-niveau (ex. FRA-04a « même dénominateur », FRA-04b « comparer à 1 ») ? À trancher en concevant les 3 premières missions.
2. Modèle de maîtrise : comment passe-t-on de « l'enfant a réussi 4 missions sur FRA-02 » à « FRA-02 est maîtrisée » ? (v1 simple : compteur de réussites récentes ; à raffiner plus tard.)
3. Vérification contre le BO officiel et les repères annuels en vigueur (les programmes ont été ajustés en 2023–2025).
